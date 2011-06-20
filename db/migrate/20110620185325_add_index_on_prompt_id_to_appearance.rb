class AddIndexOnPromptIdToAppearance < ActiveRecord::Migration
  def self.up
    add_index :appearances, :prompt_id
  end

  def self.down
    remove_index :appearances, :prompt_id
  end
end
