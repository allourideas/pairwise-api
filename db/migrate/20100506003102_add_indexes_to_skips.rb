class AddIndexesToSkips < ActiveRecord::Migration
  def self.up
	  add_index :skips, :question_id
	  add_index :skips, :prompt_id
  end

  def self.down
	  remove_index :skips, :question_id
	  remove_index :skips, :prompt_id
  end
end
