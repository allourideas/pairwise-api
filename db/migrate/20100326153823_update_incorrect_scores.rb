class UpdateIncorrectScores < ActiveRecord::Migration
  def self.up

	  # some scores were computed incorrectly as a result of a bug
	  # This only affected the cached value of the score, so we only need to recalculate the correct score
	  # for those choices voted on in the last few days
	  startDate = 2.days.ago
	  votes = Vote.find(:all, :conditions => ['created_at > ?', startDate])
	  toupdate = votes.inject(Set.new){|updatethese, v| updatethese << v.choice_id}
	  choices = Choice.find(:all, :conditions => {'id' => toupdate.to_a})

	  choices.each do |c|
		  c.compute_score!
	  end

  end

  def self.down
  end
end
