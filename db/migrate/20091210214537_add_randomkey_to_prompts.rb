class AddRandomkeyToPrompts < ActiveRecord::Migration
  def self.up
    add_column :prompts, :randomkey, :integer
  end

  def self.down
    remove_column :prompts, :randomkey
  end
end
