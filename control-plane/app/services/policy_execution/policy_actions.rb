# frozen_string_literal: true

module PolicyExecution
  module PolicyActions
    DENY             = "deny"
    ALLOW            = "allow"
    MASK             = "mask"
    REQUIRE_APPROVAL = "require_approval"

    ALL = [
      DENY,
      REQUIRE_APPROVAL,
      MASK,
      ALLOW
    ].freeze

    def self.valid?(action)
      ALL.include?(action)
    end
  end
end
