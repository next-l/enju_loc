class CreateNiiTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :nii_types do |t|
      t.string :name, index: {unique: true}, null: false
      t.text :display_name
      t.text :note
      t.integer :position

      t.timestamps
    end
  end
end
