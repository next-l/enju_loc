class CreateLocRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :loc_records do |t|
      t.string :body, null: false, index: {unique: true}
      t.references :manifestation, foreign_key: true, null: false

      t.timestamps
    end
  end
end
