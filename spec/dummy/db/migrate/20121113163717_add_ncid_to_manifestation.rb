class AddNcidToManifestation < ActiveRecord::Migration[5.2]
  def change
    add_column :manifestations, :ncid, :string
    add_index :manifestations, :ncid
  end
end
