class AddCounterCachesToChoices < ActiveRecord::Migration
  def self.up
    add_column :choices, :prompts_on_the_left_count, :integer, :default => 0
    add_column :choices, :prompts_on_the_right_count, :integer, :default => 0
    add_column :choices, :votes_count, :integer, :default => 0
    
    Choice.reset_column_information
    Choice.find(:all).each do |c|
      Choice.update_counters c.id, :prompts_on_the_left_count => c.prompts_on_the_left.length
      Choice.update_counters c.id, :prompts_on_the_right_count => c.prompts_on_the_right.length
      Choice.update_counters c.id, :votes_count => c.votes.length
    end
  end

  def self.down
    remove_column :choices, :votes_count
    remove_column :choices, :prompts_on_the_right_count
    remove_column :choices, :prompts_on_the_left_count
  end
end
