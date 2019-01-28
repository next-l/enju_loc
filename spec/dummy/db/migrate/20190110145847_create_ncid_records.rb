class CreateNcidRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :ncid_records do |t|
      t.string :body, null: false, index: {unique: true}
      t.references :manifestation, foreign_key: true, null: false, type: :uuid

      t.timestamps
    end
  end
end
