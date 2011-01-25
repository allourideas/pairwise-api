class AddShowResultsToQuestions < ActiveRecord::Migration
  def self.up
    add_column :questions, :show_results, :boolean, :default => 1
  end

  def self.down
    remove_column :questions, :show_results
  end
end
