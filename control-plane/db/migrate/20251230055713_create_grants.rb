class CreateGrants < ActiveRecord::Migration[7.1]
  def change
    create_table :grants, id: :uuid do |t|
      t.references :organization, null: false, type: :uuid, foreign_key: true
      t.references :user,         null: false, type: :uuid, foreign_key: true

      t.string  :dataset, null: false
      t.jsonb   :fields,      null: false, default: []
      t.jsonb   :mask_fields, null: false, default: []

      t.string  :decision,  null: false
      t.string  :policy_id
      t.string  :reason

      t.integer :ttl_seconds, null: false
      t.datetime :expires_at, null: false

      t.string :session_token, null: false

      t.timestamps
    end

    add_index :grants, [:organization_id, :dataset]
    add_index :grants, :expires_at
  end
end
