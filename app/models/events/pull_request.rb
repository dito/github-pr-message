require './app/models/events/base'

module Events
  class PullRequest < Events::Base
    attr_reader :payload

    def initialize(payload:)
      @payload = payload
    end

    def hook
      return unless payload
      return unless r2m_title?
      return unless r2m_branch?
      return unless body_blank?
      return unless opened?

      get_list_commits
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

    def body_blank?
      pull_request_body == ""
    end

    def pull_request_body
      payload.dig('pull_request', 'body')
    end

    def pull_request_number
      payload.dig('pull_request', 'number')
    end

    def opened?
      payload['action'] == 'opened'
    end
  end
end
