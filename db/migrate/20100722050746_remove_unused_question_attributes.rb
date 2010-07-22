class RemoveUnusedQuestionAttributes < ActiveRecord::Migration
  def self.up
    remove_column :questions, :active_items_count
    remove_column :questions, :bloom
    remove_column :questions, :first_prompt_algorithm_id
    remove_column :questions, :items_count
  end

  def self.down
    add_column :questions, :active_items_count, :integer, :default => 0
    add_column :questions, :bloom, :text
    add_column :questions, :first_prompt_algorithm_id, :integer
    add_column :questions, :items_count, :integer, :default => 0
  end
end
