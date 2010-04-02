class CreateAppearances < ActiveRecord::Migration
  def self.up
    create_table :appearances do |table|
      table.integer :voter_id
      table.integer :site_id
      table.integer :prompt_id
      table.integer :question_id
      table.string :lookup
      table.timestamps
    end

    add_column :votes, :appearance_id, :integer
    add_index :appearances, :lookup

  end

  def self.down
    drop_table :appearances
    remove_column :votes, :appearance_id, :integer
  end
end
