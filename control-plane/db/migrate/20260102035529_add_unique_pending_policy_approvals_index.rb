# frozen_string_literal: true

class AddUniquePendingPolicyApprovalsIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :policy_approvals,
              [:organization_id, :requester_id, :dataset, :approver_role, :fields],
              unique: true,
              where: "state = 'pending'",
              name: "uniq_pending_policy_approvals",
              algorithm: :concurrently
  end
end
