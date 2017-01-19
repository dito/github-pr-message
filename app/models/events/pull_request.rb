require 'octokit'
require 'erb'
require 'yaml'

module Events
  class PullRequest
    attr_reader :payload

    def initialize(payload:)
      @payload = payload
    end

    def hook
      return if payload.nil? || payload.empty?
      return unless r2m_title?
      return unless r2m_branch?
      return unless body_empty?
      return unless opened_or_edited?
      return unless repository_white?

      set_merge_commit_number_and_titles
      set_body_params
      update_pull_request
    end

    private

    def r2m_title?
      payload.dig('pull_request', 'title') == 'r2m'
    end

    def r2m_branch?
      from_release_branch? && to_master_branch?
    end

    def from_release_branch?
      payload.dig('pull_request', 'head', 'ref') == 'release'
    end

    def to_master_branch?
      payload.dig('pull_request', 'base', 'ref') == 'master'
    end

    def body_empty?
      pull_request_body.empty? || pull_request_body == "\r\n"
    end

    def pull_request_body
      payload.dig('pull_request', 'body')
    end

    def pull_request_number
      payload.dig('pull_request', 'number')
    end

    def opened_or_edited?
      ['opened', 'reopened', 'edited'].include?(payload['action'])
    end

    def get_commits
      client.pull_commits("#{organization_name}/#{repository_name}", pull_request_number)
    end

    def merge_commits(included_all_commits = get_commits)
      included_all_commits.select{ |s| s['commit']['message'] =~ /\AMerge pull request (#\d+) from .*\n\n(.+)\Z/m }
    end

    def set_merge_commit_number_and_titles
      @merge_commit_number_and_titles =
        merge_commits
          .map(&:commit)
          .map(&:message)
          .each_with_object([]) do |s, a|
          s =~ /\AMerge pull request #(\d+) from .*\n\n(.+)\Z/m
          a << { number: $1, title: $2 } if $1
        end
    end

    def set_body_params
      @relese_contents = ERB::Util.html_escape(@merge_commit_number_and_titles.map{|a|'#' + a[:number] + ' ' + a[:title]}.join("\n"))
      merge_commit_numbers = @merge_commit_number_and_titles.map{ |h| h[:number] }

      @developers, @assignees = [], []

      merge_commit_numbers.each do |merge_commit_number|
        @merge_commit_issue = client.issue("#{organization_name}/#{repository_name}", merge_commit_number)
        @developers << @merge_commit_issue[:user][:login]
        @assignees << @merge_commit_issue[:assignees]&.map{ |assignee| assignee['login'] }
      end
    end

    def decorate_body
      @decorate_body = <<EOS
サービス： #{repository_name}
PR_url： #{pull_request_url}
説明：
#{@relese_contents}
実装者： #{display_names(@developers)}
レビュワー： #{display_names(@assignees.flatten)}
EOS
    end

    def update_pull_request
      client.update_issue("#{organization_name}/#{repository_name}", pull_request_number, body: decorate_body)
    rescue Octokit::NotFound
      puts "Does #{repository_name} have 'write' permission?"
    end

    def client
      @client ||= Octokit::Client.new(access_token: ENV.fetch('GITHUB_API_TOKEN'))
    end

    def repository_name
      payload.dig('repository', 'name')
    end

    def organization_name
      payload.dig('repository', 'full_name')&.split('/')&.first
    end

    def pull_request_url
      payload.dig('pull_request', 'html_url')
    end

    def auther_name
      payload.dig('pull_request', 'assignee', 'login')
    end

    def repository_white?
      repos_white_list = ENV.fetch('TARGET_REPOS').split(',')
      repos_white_list.include?(organization_name + '/' + repository_name)
    end

    def display_names(user_ids)
      config = YAML.load_file('./config/user_names.yml')

      user_ids.uniq.map { |user_id| config['github_user_ids'].send('[]', user_id) }.join('、')
    end
  end
end
