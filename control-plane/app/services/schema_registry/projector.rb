# frozen_string_literal: true

module SchemaRegistry
  class Projector
    def self.apply_bundle!(org:, bundle:, bundle_version:, actor:)
      datasets = bundle.fetch("registry").fetch("datasets")

      SchemaRegistryEntry.transaction do
        datasets.each do |ds|
          SchemaRegistryEntry.upsert(
            {
              id: existing_id_for(org, ds["name"]),
              organization_id: org.id,
              dataset_name: ds.fetch("name"),
              datasource_name: ds.fetch("datasource"),
              fields: ds.fetch("fields"),
              source: "bundle",
              bundle_version: bundle_version,
              metadata: {
                projected_at: Time.current.iso8601,
                projected_by: actor.email
              },
              updated_at: Time.current,
              created_at: Time.current
            },
            unique_by: "idx_schema_registry_entries_org_dataset"
          )
        end
      end
    end

    def self.existing_id_for(org, dataset_name)
      SchemaRegistryEntry.find_by(organization_id: org.id, dataset_name: dataset_name)&.id
    end

    private_class_method :existing_id_for
  end
end
