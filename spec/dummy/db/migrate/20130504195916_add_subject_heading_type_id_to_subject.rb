class AddSubjectHeadingTypeIdToSubject < ActiveRecord::Migration[5.1]
  def change
    add_reference :subjects, :subject_heading_type, foreign_key: true, null: false
  end
end
