# frozen_string_literal: true

class CreateDatasources < ActiveRecord::Migration[7.1]
  def change
    enable_extension "citext"

    create_table :datasources, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid

      t.citext :name, null: false
      t.string :engine, null: false

      t.text :username_encrypted
      t.text :password_encrypted
      t.jsonb :config, default: {}

      t.timestamps
    end

    add_index :datasources, [:organization_id, :name], unique: true
  end
end
