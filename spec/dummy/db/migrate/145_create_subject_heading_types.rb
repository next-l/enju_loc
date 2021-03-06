class CreateSubjectHeadingTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :subject_heading_types do |t|
      t.string :name, null: false
      t.text :display_name
      t.text :note
      t.integer :position

      t.timestamps
    end
  end
end
