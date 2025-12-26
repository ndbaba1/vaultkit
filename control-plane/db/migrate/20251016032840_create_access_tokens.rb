class CreateAccessTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :access_tokens, id: :uuid do |t|
      t.references :organization, type: :uuid, null: false
      t.string :name, null: false
      t.string :token_digest, null: false
      t.datetime :expires_at
      t.boolean :active, default: true
      t.timestamps
    end
    
    add_index :access_tokens, :token_digest, unique: true
  end
end
