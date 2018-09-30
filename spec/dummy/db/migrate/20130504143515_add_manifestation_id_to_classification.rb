class AddManifestationIdToClassification < ActiveRecord::Migration[5.1]
  def change
    add_reference :classifications, :manifestation, foreign_key: true, type: :uuid
  end
end
