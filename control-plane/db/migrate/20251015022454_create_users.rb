class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string :email, null: false
      t.string :encrypted_password
      t.string :full_name
      t.string :role, default: "member"
      t.references :organization, type: :uuid, null: false, foreign_key: true

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
