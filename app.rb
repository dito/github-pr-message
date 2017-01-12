require 'json'
require 'rack/github_webhooks'
require 'sinatra/base'
require "sinatra/config_file"
require './app/models/webhook'

class App < Sinatra::Base
  register Sinatra::ConfigFile
  config_file './config/user_names.yml'

  use Rack::GithubWebhooks, secret: ENV.fetch('SECRET_TOKEN', '')

  post "/#{ENV['ENTRY_POINT']}" do
    Webhook.run(event_type: request.env['HTTP_X_GITHUB_EVENT'], payload: payload)
    [204]
  end

  private

  def payload
    JSON.parse(request.body.read)
  rescue JSON::ParserError
    {}
  end
end
