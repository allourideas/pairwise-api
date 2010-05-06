class AddChoiceIndexesToPrompts < ActiveRecord::Migration
  def self.up
	  add_index :prompts, :left_choice_id
	  add_index :prompts, :right_choice_id
  end

  def self.down
	  remove_index :prompts, :left_choice_id
	  remove_index :prompts, :right_choice_id
  end
end
