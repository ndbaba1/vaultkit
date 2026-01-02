# frozen_string_literal: true

require Rails.root.join("app/audit_sinks/vaultkit_sink")
require Rails.root.join("app/services/audit_logger")

AUDIT_LOGGER = AuditLogger.new(
  sinks: [
    AuditSinks::VaultkitSink.new
    # AuditSinks::ElasticSink.new(client: ...)
    # AuditSinks::KafkaSink.new(producer: ...)
  ]
)
