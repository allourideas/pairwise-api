class AddQuestionIdToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :question_id, :integer
  end

  def self.down
    remove_column :items, :question_id
  end
end
