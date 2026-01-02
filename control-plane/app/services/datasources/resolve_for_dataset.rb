# frozen_string_literal: true

module Datasources
  class ResolveForDataset
    def self.call!(org:, dataset:)
      bundle = org.active_policy_bundle
      raise "No active policy bundle for organization" unless bundle

      registry = bundle.fetch("registry")

      entry =
        registry.fetch("datasets", [])
                .find { |d| d["name"] == dataset }

      raise ArgumentError, "Unknown dataset: #{dataset}" unless entry

      org.datasources.find_by!(
        name: entry.fetch("datasource")
      )
    end
  end
end
