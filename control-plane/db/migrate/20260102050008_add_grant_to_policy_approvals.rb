class AddGrantToPolicyApprovals < ActiveRecord::Migration[7.1]
  def change
    add_reference :policy_approvals, :grant, type: :uuid, foreign_key: true
  end
end
