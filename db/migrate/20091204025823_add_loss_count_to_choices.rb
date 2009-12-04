class AddLossCountToChoices < ActiveRecord::Migration
  def self.up
    add_column :choices, :loss_count, :integer, :default => 0
  end

  def self.down
    remove_column :choices, :loss_count
  end
end
