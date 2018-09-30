class AddLabelToClassification < ActiveRecord::Migration[5.1]
  def change
    add_column :classifications, :label, :string
  end
end
