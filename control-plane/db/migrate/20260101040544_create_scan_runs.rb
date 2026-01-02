class CreateScanRuns < ActiveRecord::Migration[7.1]
  def change
    create_table :scan_runs, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.string :datasource_name, null: false
      t.string :status, null: false, default: "queued" # queued|completed|failed

      t.jsonb :raw_schema, null: false, default: {}       # introspected tables/cols
      t.jsonb :classified_schema, null: false, default: {} # classifier output
      t.jsonb :diff, null: false, default: {}              # proposed changes

      t.text :error

      t.timestamps
    end

    add_index :scan_runs, [:organization_id, :datasource_name, :created_at]
  end
end
