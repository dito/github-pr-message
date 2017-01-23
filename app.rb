require 'json'
require 'rack/github_webhooks'
require 'sinatra/base'
require './app/models/pull_request'

class App < Sinatra::Base
  use Rack::GithubWebhooks, secret: ENV.fetch('SECRET_TOKEN', '')

  post "/#{ENV['ENTRY_POINT']}" do
    payload = JSON.parse(request.body.read) rescue {}
    return if payload.nil? || !payload.empty?

    if request.env['HTTP_X_GITHUB_EVENT'] == 'pull_request'
      PullRequest.new(payload).run
      [204]
    end
  end
end
