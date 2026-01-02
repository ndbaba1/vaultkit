class AddAqlAndFingerprintToGrants < ActiveRecord::Migration[7.1]
  def up
    add_column :grants, :aql, :jsonb
    add_column :grants, :fingerprint, :string

    # Backfill existing grants with a minimal safe AQL
    execute <<~SQL
      UPDATE grants
      SET aql = jsonb_build_object(
        'source_table', dataset,
        'columns', fields
      )
      WHERE aql IS NULL
    SQL

    change_column_null :grants, :aql, false

    add_index :grants, :fingerprint
    add_index :grants, :aql, using: :gin
  end

  def down
    remove_index :grants, :aql
    remove_index :grants, :fingerprint

    remove_column :grants, :fingerprint
    remove_column :grants, :aql
  end
end
