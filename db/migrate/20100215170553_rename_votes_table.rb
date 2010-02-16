class RenameVotesTable < ActiveRecord::Migration
  def self.up
	  rename_table :votes, :oldvotes
  end

  def self.down
	  rename_table :oldvotes, :votes
  end
end
