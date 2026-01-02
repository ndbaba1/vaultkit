# frozen_string_literal: true

module Vkit
  module Core
    module TtlParser
      def self.parse(raw)
        return nil unless raw

        case raw
        when String
          case raw
          when /^(\d+)h$/i then Regexp.last_match(1).to_i * 3600
          when /^(\d+)m$/i then Regexp.last_match(1).to_i * 60
          when /^(\d+)s$/i then Regexp.last_match(1).to_i
          else
            raise ArgumentError, "Invalid TTL format: #{raw} (use 30m, 2h, 90s)"
          end
        when Integer
          raw
        else
          raise ArgumentError, "Invalid TTL type: #{raw.class}"
        end
      end
    end
  end
end
