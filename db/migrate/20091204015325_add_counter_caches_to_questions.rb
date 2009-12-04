class AddCounterCachesToQuestions < ActiveRecord::Migration
  def self.up
    add_column :questions, :votes_count, :integer, :default => 0
    
    Question.reset_column_information
    Question.find(:all).each do |q|
      Question.update_counters q.id, :choices_count => q.choices.length
      Question.update_counters q.id, :prompts_count => q.prompts.length
      Question.update_counters q.id, :votes_count => q.votes.length
    end
  end

  def self.down
    remove_column :questions, :votes_count
  end
end
