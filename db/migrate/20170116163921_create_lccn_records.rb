class CreateLccnRecords < ActiveRecord::Migration[5.0]
  def change
    create_table :lccn_records do |t|
      t.string :body, index: {unique: true}, null: false
      t.references :manifestation, foreign_key: true, null: false, type: :uuid

      t.timestamps
    end
  end
end