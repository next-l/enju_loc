class AddExtentOfTextToManifestation < ActiveRecord::Migration[4.2]
  def change
    add_column :manifestations, :extent_of_text, :text
  end
end
