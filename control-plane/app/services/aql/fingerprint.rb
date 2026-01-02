# frozen_string_literal: true

require "digest"

module Aql
  class Fingerprint
    def self.call(aql)
      Digest::SHA256.hexdigest(canonical_json(aql))
    end

    def self.canonical_json(aql)
      canonicalize(aql).to_json
    end

    def self.canonicalize(node)
      case node
      when Hash
        node
          .sort_by { |k, _| k.to_s }
          .to_h
          .transform_values { |v| canonicalize(v) }
      when Array
        node.map { |v| canonicalize(v) }
      else
        node
      end
    end
  end
end
