class AddVistorIndexToVotesTable < ActiveRecord::Migration
  def self.up
	  add_index :votes, :voter_id
	  add_index :items, :creator_id
  end

  def self.down
	  remove_index :votes, :voter_id
	  remove_index :items, :creator_id
  end
end
