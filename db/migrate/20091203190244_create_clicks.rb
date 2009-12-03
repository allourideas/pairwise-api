class CreateClicks < ActiveRecord::Migration
  def self.up
    create_table :clicks do |table|
      table.integer :site_id
      table.integer :visitor_id
      table.text :additional_info
      table.timestamps
    end

  end

  def self.down
    drop_table :clicks
  end
end
