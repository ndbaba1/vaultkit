class CreateDataSources < ActiveRecord::Migration[7.1]
  def change
    create_table :data_sources, id: :uuid do |t|
      t.string  :name,     null: false
      t.string  :engine,   null: false # "postgres", "mysql", "snowflake"
      t.string  :mode,     null: false # "secret_provider" | "local_encrypted"
      t.string  :provider              # "aws" | "gcp" | "azure" | "vault" (when mode=secret_provider)

      # App-level encrypted columns
      t.text    :config_encrypted       # provider config (e.g., secret_ref/role_arn/external_id)
      t.text    :local_credentials_encrypted  # plaintext creds when mode=local_encrypted

      # Multi-tenancy / audit
      t.uuid    :org_id,    null: false
      t.uuid    :created_by, null: false
      t.jsonb   :metadata,  null: false, default: {} # tags, labels, notes

      t.timestamps
    end

    add_index :data_sources, [:org_id, :name], unique: true
    add_index :data_sources, :engine
    add_index :data_sources, :mode
    add_index :data_sources, :provider
  end
end
