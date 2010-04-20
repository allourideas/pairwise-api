class AddCatchupBoolToQuestions < ActiveRecord::Migration
  def self.up
	  add_column :questions, :uses_catchup, :boolean, :default => false
  end

  def self.down
	  remove_column :questions, :uses_catchup
  end
end
