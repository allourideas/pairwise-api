class CreateVisitors < ActiveRecord::Migration
  def self.up
    create_table :visitors do |table|
      table.integer :site_id
      table.string :identifier, :default => ""
      table.text :tracking
      table.boolean :activated
      table.integer :user_id
      table.timestamps
    end

  end

  def self.down
    drop_table :visitors
  end
end
