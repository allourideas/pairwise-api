class AddIndexForCreatedAtQuestionIdToVotes < ActiveRecord::Migration
  # this is for a query in the admin area
  # EXPLAIN SELECT count(*) AS count_all, votes.question_id AS votes_question_id FROM `votes` INNER JOIN `questions` ON `questions`.id = `votes`.question_id  WHERE (votes.created_at > '2011-06-01') AND (votes.valid_record = 1) GROUP BY votes.question_id;
  def self.up
    add_index :votes, [:created_at, :question_id]
  end

  def self.down
    remove_index :votes, [:created_at, :question_id]
  end
end
