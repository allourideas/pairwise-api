class AddFlagForIdeaActivationToQuestions < ActiveRecord::Migration
  def self.up
    add_column :questions, :it_should_autoactivate_ideas, :boolean, :default => false
  end

  def self.down
    remove_column :questions, :it_should_autoactivate_ideas
  end
end
