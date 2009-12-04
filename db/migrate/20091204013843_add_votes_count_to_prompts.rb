class AddVotesCountToPrompts < ActiveRecord::Migration
  def self.up
    add_column :prompts, :votes_count, :integer, :default => 0
    
    Prompt.reset_column_information
    Prompt.find(:all).each do |p|
      Prompt.update_counters p.id, :votes_count => p.votes.length
    end
    
  end

  def self.down
    remove_column :prompts, :votes_count
  end
end
