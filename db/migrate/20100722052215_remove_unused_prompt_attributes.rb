class RemoveUnusedPromptAttributes < ActiveRecord::Migration
  def self.up
    remove_column :prompts, :active
    remove_column :prompts, :algorithm_id
    remove_column :prompts, :randomkey
    remove_column :prompts, :voter_id
  end

  def self.down
    add_column :prompts, :active, :boolean
    add_column :prompts, :algorithm_id, :integer
    add_column :prompts, :randomkey, :integer
    add_column :prompts, :voter_id, :integer
  end
end
