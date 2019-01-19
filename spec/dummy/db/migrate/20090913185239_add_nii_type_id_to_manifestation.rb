class AddNiiTypeIdToManifestation < ActiveRecord::Migration[5.2]
  def change
    add_reference :manifestations, :nii_type
  end
end
