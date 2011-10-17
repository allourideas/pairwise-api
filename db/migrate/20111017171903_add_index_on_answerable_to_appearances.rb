class AddIndexOnAnswerableToAppearances < ActiveRecord::Migration
  def self.up
    add_index :appearances, [:answerable_id, :answerable_type]
  end

  def self.down
    remove_index :appearances, [:answerable_id, :answerable_type]
  end
end
