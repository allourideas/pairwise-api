class CreateSkipsModel < ActiveRecord::Migration
  def self.up
    create_table :skips do |table|
      table.text :tracking
      table.integer :site_id
      table.integer :skipper_id
      table.integer :question_id
      table.integer :prompt_id
      table.integer :appearance_id
      table.integer :time_viewed #msecs
      table.timestamps
    end

  end

  def self.down
    drop_table :skips
  end
end
