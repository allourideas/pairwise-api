class UpdateVoteCountForQuestions < ActiveRecord::Migration
  def self.up
    Question.reset_column_information
    Question.find(:all).each do |q|
      Question.update_counters q.id, :votes_count => q.choices.collect(&:votes_count).sum
    end
  end

  def self.down
  end
end
