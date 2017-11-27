class RenameManifestationPeriodicalToSerial < ActiveRecord::Migration[5.1]
  def change
    rename_column :manifestations, :periodical, :serial
  end
end
