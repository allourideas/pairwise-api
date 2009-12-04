class AddPromptsCountToChoices < ActiveRecord::Migration
  def self.up
    add_column :choices, :prompts_count, :integer, :default => 0
    
    Choice.reset_column_information
    Choice.find(:all).each do |c|
      Choice.update_counters c.id, :prompts_count => c.prompts_on_the_left_count + c.prompts_on_the_right_count
    end
  end

  def self.down
    remove_column :choices, :prompts_count
  end
end
