class CreateExports < ActiveRecord::Migration
  def self.up
    create_table :exports do |table|
      table.string :name, :default => ""
      table.integer :question_id
      table.binary :data, :limit => 16.megabyte
      table.boolean :compressed, :default => 0
    end
    add_index :exports, :name
  end

  def self.down
    drop_table :exports
  end
end
