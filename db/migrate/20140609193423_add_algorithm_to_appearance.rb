class AddAlgorithmToAppearance < ActiveRecord::Migration
  def self.up
    add_column :appearances, :algorithm_name, :string
    add_column :appearances, :algorithm_metadata, :text
  end

  def self.down
    remove_column :appearances, :algorithm_name
    remove_column :appearances, :algorithm_metadata
  end
end
