require 'octokit'

module Events
  class Base
    private

    def get_commits
      client.pull_commits("#{organization_name}/#{repository_name}", pull_request_number)
    end

    def merge_commits
      get_commits.select{ |s| s['commit']['message'] =~ /\AMerge pull request (#\d+) from .*\n\n(.+)\Z/m }
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
      @relese_contents = ERB::Util.html_escape(@merge_commit_number_and_titles.map{|a|'#' + a[:number] + ' ' + a[:title].gsub('[ci skip]', '')}.join("\n"))
      merge_commit_numbers = @merge_commit_number_and_titles.map{ |h| h[:number] }

      @developers, @reviewers = [], []

      merge_commit_numbers.each do |merge_commit_number|
        @merge_commit_issue = client.issue("#{organization_name}/#{repository_name}", merge_commit_number)
        pull_request_review_requests = client.pull_request_review_requests("#{organization_name}/#{repository_name}", merge_commit_number)
        @developers << @merge_commit_issue[:user][:login]
        @reviewers << pull_request_review_requests&.map{ |reviewer| reviewer['login'] }
      end
    end

    def decorate_body
      @decorate_body = <<EOS
サービス： #{repository_name}
PR_url： #{pull_request_url}
説明：
#{@relese_contents}
実装者： #{@developers.flatten.uniq.join(', ')}
レビュワー： #{@reviewers.flatten.uniq.join(', ')}
#{template}
EOS
    end

    def update_pull_request
      client.update_issue("#{organization_name}/#{repository_name}", pull_request_number, body: decorate_body)
    rescue Octokit::NotFound
      puts "Does #{repository_name} have 'write' permission?"
    end

    def client
      @client ||= Octokit::Client.new(access_token: ENV.fetch('GITHUB_API_TOKEN'), auto_paginate: true)
    end

    def repository_name
      payload.dig('repository', 'name')
    end

    alias_method :team_name, :repository_name

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

    def template
      @template ||= (team['description'] =~ /r2mテンプレ:(.*)/m; $1)
    end

    def team
      @team ||= client.organization_teams(organization_name, { per_page: 100 })&.find { |t| t['name'] == team_name }
    end
  end
end
