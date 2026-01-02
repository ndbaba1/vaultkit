class AddSlugToOrganizations < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    add_column :organizations, :slug, :string

    say_with_time "Backfilling organization slugs" do
      execute <<~SQL
        UPDATE organizations
        SET slug = lower(regexp_replace(name, '[^a-zA-Z0-9]+', '-', 'g'))
        WHERE slug IS NULL;
      SQL
    end

    add_index :organizations, :slug, unique: true, algorithm: :concurrently

    change_column_null :organizations, :slug, false
  end

  def down
    remove_index :organizations, :slug
    remove_column :organizations, :slug
  end
end
