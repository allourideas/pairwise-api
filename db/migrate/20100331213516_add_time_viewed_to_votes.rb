class AddTimeViewedToVotes < ActiveRecord::Migration
  def self.up
	  add_column :votes, :time_viewed, :integer #msec
  end

  def self.down
	  remove_column :votes, :time_viewed, :integer #msec
  end
end
