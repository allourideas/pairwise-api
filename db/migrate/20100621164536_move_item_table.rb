class MoveItemTable < ActiveRecord::Migration
  def self.up
	# Rather than dropping the table, let's move it in case something goes wrong
	#  feel free to delete the table if nothing goes wrong in the future
	rename_table :items, :old_items
  end

  def self.down
	rename_table :old_items, :items
  end
end
