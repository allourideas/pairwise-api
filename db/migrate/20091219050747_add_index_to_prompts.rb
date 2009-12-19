class AddIndexToPrompts < ActiveRecord::Migration
  def self.up
    add_index :prompts, [:left_choice_id, :right_choice_id]
  end

  def self.down
    remove_index :prompts, [:left_choice_id, :right_choice_id]
  end
end
