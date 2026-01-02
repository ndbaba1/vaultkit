class CreateSchemaRegistryEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :schema_registry_entries, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid

      t.string :dataset_name, null: false
      t.string :datasource_name, null: false

      t.jsonb :fields, null: false, default: []

      t.string :source, null: false # "bundle" | "scan" | "manual"

      # which bundle version produced this entry (when source=bundle)
      t.string :bundle_version

      # metadata for auditing/debug
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :schema_registry_entries,
              [:organization_id, :dataset_name],
              unique: true,
              name: "idx_schema_registry_entries_org_dataset"

    add_index :schema_registry_entries, [:organization_id, :datasource_name]
  end
end
