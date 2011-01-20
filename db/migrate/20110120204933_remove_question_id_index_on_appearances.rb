class RemoveQuestionIdIndexOnAppearances < ActiveRecord::Migration
  def self.up
    remove_index :appearances, :question_id
  end

  def self.down
    add_index :appearances, :question_id
  end
end
