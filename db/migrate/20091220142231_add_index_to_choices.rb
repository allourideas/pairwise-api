class AddIndexToChoices < ActiveRecord::Migration
  def self.up
    add_index :choices, [:question_id, :score]
  end

  def self.down
    remove_index :choices, [:question_id, :score]
  end
end
