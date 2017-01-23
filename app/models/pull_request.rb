require 'octokit'
require 'erb'
require 'yaml'

class PullRequest

  REG_COMMIT_MESSAGE = /\AMerge pull request (#\d+) from .*\n\n(.+)\Z/m

  def initialize(payload)
    set_instance_variables(payload)
  end

  def run
    return unless should_run?
    update_pull_request
  end

  private

  def set_instance_variables(payload)
    @organization_name = payload.dig('repository', 'full_name')&.split('/')&.first
    @repository_name = payload.dig('repository', 'name')
    @repository = organization_name + '/' + @repository_name
    @action =  payload.dig('action')
    @title = payload.dig('pull_request', 'title')
    @body = payload.dig('pull_request', 'body')
    @head_branch = payload.dig('pull_request', 'head', 'ref')
    @base_branch = payload.dig('pull_request', 'base', 'ref')
    @number = payload.dig('pull_request', 'number')
    @html_url = payload.dig('pull_request', 'html_url')
  end

  def should_run?
    return unless @title == 'r2m'
    return unless @head_branch == 'release' && @base_branch == 'master'
    return unless @body.empty? || @body == "\r\n"
    return unless %w(opened reopened edited).include?(@action)
    return unless target_repository?
  end

  def target_repository?
    target_repository_list = ENV.fetch('TARGET_REPOS').split(',')
    target_repository_list.include?(@repository)
  end

  def client
    @client ||= Octokit::Client.new(access_token: ENV.fetch('GITHUB_API_TOKEN'))
  end

  def merge_commits
    commits = client.pull_commits(@repository, @number)
    commits.select { |commit| commit.dig('commit','message') =~ REG_COMMIT_MESSAGE }
  end

  def set_body_params
    merge_commit_number_and_titles =
      merge_commits
        .map { |commit| commit.dig('commit','message') }
        .map { |message| message =~ REG_COMMIT_MESSAGE; { number: $1, title: $2 } if $1 }
    @release_contents = ERB::Util.html_escape(merge_commit_number_and_titles.map { |a| '#' + a[:number] + ' ' + a[:title] }.join("\n"))
    @developers, @assignees = [], []
    merge_commit_numbers = merge_commit_number_and_titles.map { |h| h[:number] }
    merge_commit_numbers.each do |merge_commit_number|
      merge_commit_issue = client.issue(@repository, merge_commit_number)
      @developers << merge_commit_issue[:user][:login]
      @assignees << merge_commit_issue[:assignees]&.map { |assignee| assignee['login'] }
    end
  end

  def update_pull_request
    set_body_params
    client.update_issue(@repository, @number, body: decorate_body)
  rescue Octokit::NotFound
    puts "Does #{@repository_name} have 'write' permission?"
  end

  def decorate_body
    <<EOS
サービス： #{@repository_name}
PR_url： #{@html_url}
説明：
#{@release_contents}
実装者： #{display_names(@developers)}
レビュワー： #{display_names(@assignees.flatten)}
EOS
  end

  def display_names(user_ids)
    config = YAML.load_file('./config/user_names.yml')

    user_ids.uniq.map { |user_id| config['github_user_ids'].send('[]', user_id) }.join('、')
  end
end
