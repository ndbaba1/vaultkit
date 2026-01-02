# frozen_string_literal: true

class AddAqlAndFingerprintToPolicyApprovals < ActiveRecord::Migration[7.1]
  def up
    add_column :policy_approvals, :aql, :jsonb
    add_column :policy_approvals, :aql_fingerprint, :string

    execute <<~SQL
      UPDATE policy_approvals
      SET aql = jsonb_build_object(
        'source_table', dataset,
        'columns', fields
      )
      WHERE aql IS NULL
    SQL

    # Backfill fingerprint deterministically
    execute <<~SQL
      UPDATE policy_approvals
      SET aql_fingerprint = encode(
        digest(aql::text, 'sha256'),
        'hex'
      )
      WHERE aql_fingerprint IS NULL
    SQL

    change_column_null :policy_approvals, :aql, false
    change_column_null :policy_approvals, :aql_fingerprint, false

    add_index :policy_approvals, :aql, using: :gin

    add_index :policy_approvals,
              [:organization_id, :requester_id, :aql_fingerprint],
              unique: true,
              where: "state = 'pending'",
              name: "uniq_pending_policy_approvals_by_fingerprint"
  end

  def down
    remove_index :policy_approvals, name: "uniq_pending_policy_approvals_by_fingerprint"
    remove_index :policy_approvals, :aql
    remove_column :policy_approvals, :aql_fingerprint
    remove_column :policy_approvals, :aql
  end
end
