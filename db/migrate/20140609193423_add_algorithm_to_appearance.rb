class AddAlgorithmToAppearance < ActiveRecord::Migration
  def self.up
    add_column :appearances, :algorithm, :text
  end

  def self.down
    remove_column :appearances, :algorithm
  end
end
