# frozen_string_literal: true

module SchemaRegistry
  class Reconciler
    def initialize(org:, actor:)
      @org = org
      @actor = actor
    end

    def reconcile!(datasource_name:, scanned_datasets:, mode: "diff_only")
      current_entries = SchemaRegistryEntry.where(organization: @org)

      diff = SchemaRegistry::Diff.compute(
        current_entries: current_entries,
        scanned_datasets: scanned_datasets
      )

      case mode
      when "diff_only"
        return { status: "ok", mode: mode, diff: diff }

      when "apply"
        apply_scan!(datasource_name: datasource_name, scanned_datasets: scanned_datasets)
        return { status: "ok", mode: mode, applied: true, diff: diff }

      else
        raise ArgumentError, "Unknown mode: #{mode}"
      end
    end

    private

    def apply_scan!(datasource_name:, scanned_datasets:)
      SchemaRegistryEntry.transaction do
        scanned_datasets.each do |ds|
          SchemaRegistryEntry.upsert(
            {
              id: SchemaRegistryEntry.find_by(organization_id: @org.id, dataset_name: ds["name"])&.id,
              organization_id: @org.id,
              dataset_name: ds.fetch("name"),
              datasource_name: datasource_name,
              fields: ds.fetch("fields"),
              source: "scan",
              bundle_version: nil,
              metadata: {
                scanned_at: Time.current.iso8601,
                scanned_by: @actor.email
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
