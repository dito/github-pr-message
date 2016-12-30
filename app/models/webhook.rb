require './app/models/events/pull_request'

class Webhook
  class << self
    def run(event_type: , payload:)
      return if event_type.nil?

      event = event_class(event_type).new(payload: payload)
      event.hook
    rescue NameError => e
      raise unless e.message =~ /uninitialized constant/
    end

    private

    def event_class(event_type)
      Events.const_get event_type.split(/_/).map(&:capitalize).join
    end
  end
end
