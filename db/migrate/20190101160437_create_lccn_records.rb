class CreateLccnRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :lccn_records do |t|
      t.string :body, index: {unique: true}, null: false

      t.timestamps
    end
  end
end
