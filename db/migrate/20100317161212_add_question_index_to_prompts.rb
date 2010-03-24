class AddQuestionIndexToPrompts < ActiveRecord::Migration
  def self.up
	  add_index :prompts, :question_id
  end

  def self.down
	  remove_index :prompts, :question_id
  end
end
