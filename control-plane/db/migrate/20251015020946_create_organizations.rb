class CreateOrganizations < ActiveRecord::Migration[7.1]
  def change
    create_table :organizations, id: :uuid do |t|
      t.string :name, null: false
      t.string :domain
      t.string :plan, default: "free"
      t.jsonb  :metadata, null: false, default: {} # custom fields, tags, settings

      t.timestamps
    end

    add_index :organizations, :domain, unique: true
    add_index :organizations, :metadata, using: :gin
  end
end
