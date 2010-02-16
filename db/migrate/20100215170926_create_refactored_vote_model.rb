class CreateRefactoredVoteModel < ActiveRecord::Migration
  def self.up
    create_table :votes do |table|
      table.text :tracking
      table.integer :site_id
      table.integer :voter_id
      table.integer :question_id
      table.integer :prompt_id
      table.integer :choice_id
      table.integer :loser_choice_id
      table.timestamps
    end
  end

  def self.down
    drop_table :votes
  end
end
