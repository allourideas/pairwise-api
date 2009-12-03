class CreateVotes < ActiveRecord::Migration
  def self.up
    create_table :votes do |table|
      table.text :tracking
      table.integer :site_id
      table.integer :voter_id
      table.integer :voteable_id
      table.string :voteable_type, :default => ""
      table.timestamps
    end

  end

  def self.down
    drop_table :votes
  end
end
