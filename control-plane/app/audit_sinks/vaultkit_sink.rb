# frozen_string_literal: true

module AuditSinks
  class VaultkitSink
    def write(entry)
      AuditLog.create!(
        organization: entry.fetch(:organization),
        event: entry.fetch(:event),
        actor: entry[:actor],
        details: entry[:details] || {},
        occurred_at: entry[:timestamp] || Time.current
      )
    end
  end
end
