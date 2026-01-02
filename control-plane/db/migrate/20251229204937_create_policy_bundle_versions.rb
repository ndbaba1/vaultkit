class CreatePolicyBundleVersions < ActiveRecord::Migration[7.1]
  def change
    create_table :policy_bundle_versions, id: :uuid do |t|
      t.references :organization,
                   null: false,
                   type: :uuid,
                   foreign_key: true

      t.references :created_by,
                   null: true,
                   type: :uuid,
                   foreign_key: { to_table: :users }

      t.string :bundle_version, null: false
      t.string :checksum, null: false
      t.jsonb :bundle_json, null: false

      t.string :state, null: false, default: "uploaded"
      t.datetime :activated_at

      t.string :source_repo
      t.string :source_ref
      t.string :source_commit_sha

      t.timestamps
    end

    add_index :policy_bundle_versions, [:organization_id, :bundle_version], unique: true
    add_index :policy_bundle_versions, [:organization_id, :checksum], unique: true
    add_index :policy_bundle_versions, [:organization_id, :state]
  end
end
