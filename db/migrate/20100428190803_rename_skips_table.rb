class RenameSkipsTable < ActiveRecord::Migration
  def self.up
	  rename_table :skips, :oldskips
  end

  def self.down
	  rename_table :oldskips, :skips
  end
end
