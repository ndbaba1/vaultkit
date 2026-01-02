class AddRefToGrants < ActiveRecord::Migration[7.1]
  def change
    add_column :grants, :ref, :string, null: false
    add_index  :grants, :ref, unique: true
  end
end
