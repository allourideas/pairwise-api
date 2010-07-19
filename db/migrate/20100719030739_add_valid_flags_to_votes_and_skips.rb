class AddValidFlagsToVotesAndSkips < ActiveRecord::Migration
  def self.up
	  add_column :votes, :valid_record, :boolean, :default => true
	  add_column :votes, :validity_information, :string
	  add_column :skips, :valid_record, :boolean, :default => true
	  add_column :skips, :validity_information, :string
  end

  def self.down
	  remove_column :votes, :valid_record
	  remove_column :votes, :validity_information
	  remove_column :skips, :valid_record
	  remove_column :skips, :validity_information
  end
end
