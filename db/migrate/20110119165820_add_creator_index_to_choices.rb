class AddCreatorIndexToChoices < ActiveRecord::Migration
  def self.up
    add_index :choices, :creator_id
  end

  def self.down
    remove_index :choices, :creator_id
  end
end
