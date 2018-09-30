class CreateSubjects < ActiveRecord::Migration[5.1]
  def change
    create_table :subjects, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.integer :parent_id, index: true
      t.integer :use_term_id, index: true
      t.string :term, index: true
      t.text :term_transcription
      t.references :subject_type, foreign_key: true, null: false
      t.text :scope_note
      t.text :note
      t.references :required_role, default: 1, null: false, foreign_key: {to_table: :roles}
      t.integer :lock_version, default: 0, null: false
      t.timestamps
    end
  end
end
