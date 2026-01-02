# frozen_string_literal: true

module Aql
  class AuditSerializer
    def self.call(aql)
      redact_values(aql.deep_dup)
    end

    def self.redact_values(node)
      case node
      when Hash
        node.transform_values do |v|
          redact_values(v)
        end
      when Array
        node.map { |v| redact_values(v) }
      else
        if sensitive_literal?(node)
          "[REDACTED]"
        else
          node
        end
      end
    end

    def self.sensitive_literal?(value)
      value.is_a?(String) || value.is_a?(Numeric) || value == true || value == false
    end
  end
end
