# frozen_string_literal: true

module Vkit
  module Core
    module Masking
      # Args:
      #   dataset: "customers"
      #   requested_fields: ["email", "total_spend"]
      #   registry: compiled bundle registry
      #   decision: {
      #     action: "mask",
      #     masking: {
      #       "fields" => ["email"],
      #       "category" => ["pii"],
      #       "except" => ["id"]
      #     }
      #   }
      #
      # Returns:
      #   Array<String> fields to mask
      #
      def self.resolve_masks(dataset:, requested_fields:, registry:, decision:)
        return [] unless decision[:action] == "mask"

        field_meta = build_field_meta(dataset, registry)
        rules      = decision[:masking] || {}

        mask_fields   = Array(rules["fields"]).map(&:to_s)
        mask_tags     = Array(rules["category"]).map(&:to_s)
        mask_except   = Array(rules["except"]).map(&:to_s)

        requested = requested_fields.map(&:to_s)

        masked =
          if mask_fields.any?
            # Explicit allowlist
            requested & mask_fields
          elsif mask_tags.any?
            # Match tags OR sensitivity
            requested.select do |field|
              meta = field_meta[field]
              next false unless meta

              (Array(meta[:tags]) & mask_tags).any? ||
                mask_tags.include?(meta[:sensitivity])
            end
          else
            # Default: mask PII-tagged fields
            requested.select do |field|
              meta = field_meta[field]
              meta && Array(meta[:tags]).include?("pii")
            end
          end

        # Apply exclusions last
        masked - mask_except
      end

      # Helpers
      def self.build_field_meta(dataset, registry)
        datasets = registry["datasets"] || []

        ds = datasets.find { |d| d["name"].to_s == dataset.to_s }
        return {} unless ds

        Array(ds["fields"]).each_with_object({}) do |f, acc|
          acc[f["name"].to_s] = {
            type: f["type"],
            sensitivity: f["sensitivity"].to_s,
            tags: Array(f["tags"]).map(&:to_s)
          }
        end
      end
    end
  end
end
