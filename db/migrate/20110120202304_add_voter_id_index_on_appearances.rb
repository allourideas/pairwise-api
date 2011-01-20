class AddVoterIdIndexOnAppearances < ActiveRecord::Migration
  def self.up
    add_index :appearances, [:question_id, :voter_id], :name => 'index_appearances_on_question_id_voter_id'
  end

  def self.down
    remove_index :appearances, :name => :index_appearances_on_question_id_voter_id
  end
end
