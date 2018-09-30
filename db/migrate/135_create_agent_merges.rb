class CreateAgentMerges < ActiveRecord::Migration[5.1]
  def change
    create_table :agent_merges do |t|
      t.references :agent, foreign_key: true, type: :uuid, null: false
      t.references :agent_merge_list, foreign_key: true, null: false

      t.timestamps
    end
  end
end
