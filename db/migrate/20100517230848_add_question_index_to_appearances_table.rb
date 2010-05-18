class AddQuestionIndexToAppearancesTable < ActiveRecord::Migration
  def self.up
	  add_index :appearances, :question_id
  end

  def self.down
	  remove_index :appearances, :question_id
  end
end
