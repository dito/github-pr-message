require 'octokit'
require 'erb'

module Events
  class Base
    private

    def get_list_commits
      list_commits = client.pull_commits("#{organization_name}/#{repository_name}", pull_request_number)

      @commit_titles = list_commits.map(&:commit).map(&:message).each_with_object([]){ |s, a|s =~ /\AMerge pull request (#\d)+ from .*\n\n(.+)\Z/m; a << [$1, $2].join(' ') if $1}
    end

    def decorate_body
      commit_title_text = ERB::Util.html_escape(@commit_titles.join("\n"))

      @decorate_body = <<EOS
サービス： #{repository_name}
PR_url： #{pull_request_url}
説明：
#{commit_title_text}
実装者：
レビュワー：
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
  end
end
