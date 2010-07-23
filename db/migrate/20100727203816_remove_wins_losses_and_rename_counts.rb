class RemoveWinsLossesAndRenameCounts < ActiveRecord::Migration
  def self.up
    remove_column :choices, :wins
    remove_column :choices, :losses
    rename_column :choices, :votes_count, :wins
    rename_column :choices, :loss_count, :losses
  end

  def self.down
    rename_column :choices, :wins, :votes_count
    rename_column :choices, :losses, :loss_count
    add_column :choices, :wins, :integer
    add_column :choices, :losses, :integer
  end
end
