class AddInactiveChoiceCountToQuestions < ActiveRecord::Migration
  def self.up
	  add_column :questions, :inactive_choices_count, :integer, :default => 0
	  Question.reset_column_information
	  Question.find(:all).each do |q|
		  Question.update_counters(q.id, :inactive_choices_count => q.choices.inactive.size)
	  end

  end

  def self.down
	  remove_column :questions, :inactive_choices_count
  end
end
