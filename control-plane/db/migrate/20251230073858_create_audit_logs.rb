class CreateAuditLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :audit_logs do |t|
      t.references :organization, type: :uuid, null: false, foreign_key: true
      t.references :actor, type: :uuid, null: true, foreign_key: { to_table: :users }

      t.string  :event, null: false
      t.jsonb   :details, null: false, default: {}
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :audit_logs, :event
    add_index :audit_logs, :occurred_at
  end
end
