class CreateClassifications < ActiveRecord::Migration[5.1]
  def change
    create_table :classifications, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.integer :parent_id, index: true
      t.string :category, null: false, index: {unique: true}
      t.text :note
      t.references :classification_type, null: false, foreign_key: true

      t.timestamps
    end
  end
end
