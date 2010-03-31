class CreateDensities < ActiveRecord::Migration
  def self.up
    create_table :densities do |table|
      table.integer :question_id
      table.float :value
      table.string :type, :default => ""
      table.timestamps
    end

  end

  def self.down
    drop_table :densities
  end
end
