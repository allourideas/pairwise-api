class AddIndexesToVote < ActiveRecord::Migration
  def self.up
    add_index(:votes, :loser_choice_id, :name => 'loser_choice_id_idx')
    add_index(:votes, :choice_id, :name => 'choice_id_idx')
    add_index(:votes, :question_id, :name => 'question_id_idx')
  end

  def self.down
    remove_index(:votes, :name => :loser_choice_id_idx)
    remove_index(:votes, :name => :choice_id_idx)
    remove_index(:votes, :name => :question_id_idx)
  end
end
