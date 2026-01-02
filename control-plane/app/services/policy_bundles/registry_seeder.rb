# frozen_string_literal: true

module PolicyBundles
  class RegistrySeeder
    def self.seed!(org:, bundle_version:, actor:)
      registry = bundle_version.bundle_json.fetch("registry")
      datasets = registry.fetch("datasets", [])

      SchemaRegistryEntry.transaction do
        datasets.each do |dataset|
          SchemaRegistryEntry.upsert(
            {
              organization_id: org.id,
              dataset_name: dataset.fetch("name"),
              datasource_name: dataset.fetch("datasource"),
              fields: dataset.fetch("fields"),
              source: "bundle",
              bundle_version: bundle_version.bundle_version,
              metadata: {
                seeded_at: Time.current.iso8601,
                seeded_by: actor.email
              },
              updated_at: Time.current,
              created_at: Time.current
            },
            unique_by: "idx_schema_registry_entries_org_dataset"
          )
        end
      end
    end
  end
end
