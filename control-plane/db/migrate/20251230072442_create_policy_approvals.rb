class CreatePolicyApprovals < ActiveRecord::Migration[7.1]
  def change
    create_table :policy_approvals do |t|
      t.references :organization, null: false, type: :uuid, foreign_key: true
      t.references :requester,    null: false, type: :uuid, foreign_key: { to_table: :users }
      t.references :approver,     null: true,  type: :uuid, foreign_key: { to_table: :users }

      t.string  :dataset, null: false
      t.jsonb   :fields,  null: false, default: []

      t.string  :approver_role
      t.string  :reason

      t.string  :state, null: false, default: "pending" # pending / approved / denied

      t.datetime :approved_at

      t.timestamps
    end

    add_index :policy_approvals, [:organization_id, :state]
  end
end
