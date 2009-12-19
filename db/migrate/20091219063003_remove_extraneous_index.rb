class RemoveExtraneousIndex < ActiveRecord::Migration
  def self.up
    remove_index :prompts, [:left_choice_id, :right_choice_id]
  end

  def self.down
    add_index :prompts, [:left_choice_id, :right_choice_id]
  end
end
