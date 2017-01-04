require 'octokit'
require 'erb'

module Events
  class Base
    private

    def get_list_commits
      @list_commits = client.pull_commits("#{organization_name}/#{repository_name}", pull_request_number)

      set_merge_commits
      get_merge_commit_numbers
      update_assignees
    end

    def set_merge_commits
      @merge_commits = @list_commits.select{ |s|s['commit']['message'] =~ /\AMerge pull request (#\d)+ from .*\n\n(.+)\Z/m}
    end

    def get_merge_commit_numbers
      @merge_commit_number_and_titles = @merge_commits.map(&:commit).map(&:message).each_with_object([]){ |s, a|s =~ /\AMerge pull request (#\d)+ from .*\n\n(.+)\Z/m; a << [$1, $2] if $1}
      @merge_commit_numbers = @merge_commit_number_and_titles.map(&:first).map{ |s|s[1..-1] }
    end

    def update_assignees
      @assignees ||= []
      @assignees += @merge_commit_numbers.flat_map do |commit_number|
        assignees = client.issue("#{organization_name}/#{repository_name}", commit_number)[:assignees] || []
        assignees.map{ |assignee| assignee['login'] }
      end.compact
    end

    def decorate_body
      commit_title_text = ERB::Util.html_escape(@merge_commit_number_and_titles.map{|a|a.join(' ')}.join("\n"))

      @decorate_body = <<EOS
サービス： #{repository_name}
PR_url： #{pull_request_url}
説明：
#{commit_title_text}
実装者： #{auther_name}
レビュワー： #{@assignees.uniq.join(' ')}
EOS
    end

    def update_pull_request
      client.update_issue("#{organization_name}/#{repository_name}", pull_request_number, body: decorate_body)
    rescue Octokit::NotFound
      puts "Does #{team_name} have 'write' permission?"
    end

    def client
      @client ||= Octokit::Client.new(access_token: ENV.fetch('GITHUB_API_TOKEN'))
    end

    def team
      @team ||= client.organization_teams(organization_name, { per_page: 100 })&.find { |t| t['name'] == team_name }
    end

    def repository_name
      payload.dig('repository', 'name')
    end

    def organization_name
      payload.dig('repository', 'full_name')&.split('/')&.first
    end

    def team_name_by_phrase(content)
      return @team_name if @team_name ||= nil

      assign_phrase = ENV.fetch('ASSIGN_PHRASE') # Please assign %team
      assign_phrase_pattern = Regexp.new(assign_phrase.sub('%team', '(?<team_name>.+)'))
      @team_name = content&.match(assign_phrase_pattern)&.[](:team_name)
    end

    def pull_request_url
      payload.dig('pull_request', 'html_url')
    end

    def auther_name
      payload.dig('pull_request', 'assignee', 'login')
    end
  end
end
