class CreateFlags < ActiveRecord::Migration
  def self.up
    create_table :flags do |table|
      table.string :explanation, :default => ""
      table.integer :visitor_id
      table.integer :choice_id
      table.integer :question_id
      table.integer :site_id
      table.timestamps
    end

  end

  def self.down
    drop_table :flags
  end
end
