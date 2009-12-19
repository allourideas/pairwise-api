class CreateVisitorIndexes < ActiveRecord::Migration
  def self.up
    add_index :visitors, [:identifier, :site_id], :unique => true
  end

  def self.down
    remove_index :visitors, [:identifier, :site_id]
  end
end
