# frozen_string_literal: true

module Vkit
  module Core
    module Matchers
      class TimeWindow
        # rule example:
        # {
        #   "after"  => "09:00",
        #   "before" => "18:00"
        # }
        def self.matches?(rule, now = Time.current)
          return true unless rule.is_a?(Hash)

          after  = parse_minutes(rule["after"])
          before = parse_minutes(rule["before"])

          return true if after.nil? || before.nil?

          current = now.hour * 60 + now.min

          if after < before
            # Normal window (e.g. 09:00–18:00)
            current.between?(after, before)
          else
            # Wraparound window (e.g. 18:00–09:00)
            current >= after || current <= before
          end
        end

        def self.parse_minutes(value)
          return nil if value.nil?

          h, m = value.to_s.split(":").map(&:to_i)
          (h * 60) + m
        rescue
          nil
        end
      end
    end
  end
end
