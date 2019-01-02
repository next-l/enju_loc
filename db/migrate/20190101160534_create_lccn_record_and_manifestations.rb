class CreateLccnRecordAndManifestations < ActiveRecord::Migration[5.2]
  def change
    create_table :lccn_record_and_manifestations do |t|
      t.references :lccn_record, foreign_key: true, null: false
      t.references :manifestation, foreign_key: true, null: false
      t.timestamps
    end
    add_index :lccn_record_and_manifestations, [:lccn_record_id, :manifestation_id], unique: true, name: 'index_lccn_record_and_manifestations_on_lccn_and_manifestation'
  end
end
