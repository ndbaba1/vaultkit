# frozen_string_literal: true

module Aql
  class Canonicalizer
    def self.call(aql:, allowed_fields:, masked_fields:)
      raise ArgumentError, "AQL is required for canonicalization" if aql.nil?

      canonical = aql.deep_dup

      canonical["columns"] =
        Array(canonical["columns"]).select do |col|
          allowed_fields.include?(strip(col))
        end

      canonical["columns"] =
        canonical["columns"].map do |col|
          masked_fields.include?(strip(col)) ? mask(col) : col
        end

      canonical
    end

    def self.strip(value)
      value.to_s.split(".", 2).last
    end

    def self.mask(field)
      "MASK(#{field})"
    end
  end
end
