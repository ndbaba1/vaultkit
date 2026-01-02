require "json_schemer"
require "digest"

module PolicyBundles
  class Validator
    class InvalidBundle < StandardError; end

    SCHEMA = JSON.parse(File.read(Rails.root.join("config/schemas/policy_bundle.schema.json")))

    def self.validate!(bundle)
      schemer = JSONSchemer.schema(SCHEMA)
      errors = schemer.validate(bundle).to_a
      raise InvalidBundle, "Schema errors: #{errors.first(5)}" if errors.any?

      expected = bundle.dig("bundle", "checksum")
      raise InvalidBundle, "Missing checksum" if expected.to_s.empty?

      canonical = canonical_json(bundle.deep_merge("bundle" => bundle["bundle"].merge("checksum" => "")))
      actual = Digest::SHA256.hexdigest(canonical)

      raise InvalidBundle, "Checksum mismatch (expected=#{expected}, actual=#{actual})" unless secure_compare(expected, actual)

      true
    end

    def self.canonical_json(obj)
      JSON.generate(sort_keys_deep(obj))
    end

    def self.sort_keys_deep(value)
      case value
      when Hash
        value.keys.sort.each_with_object({}) { |k, h| h[k] = sort_keys_deep(value[k]) }
      when Array
        value.map { |v| sort_keys_deep(v) }
      else
        value
      end
    end

    def self.secure_compare(a, b)
      ActiveSupport::SecurityUtils.secure_compare(a, b)
    end
  end
end
