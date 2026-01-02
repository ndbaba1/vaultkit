# frozen_string_literal: true

class AuditLogger
  def initialize(sinks:)
    @sinks = sinks
  end

  def log(event:, actor:, organization:, details: {})
    entry = {
      id: SecureRandom.uuid,
      event: event,
      actor: actor,
      organization: organization,
      details: details,
      timestamp: Time.current
    }

    @sinks.each { |sink| sink.write(entry) }
    entry
  end
end
