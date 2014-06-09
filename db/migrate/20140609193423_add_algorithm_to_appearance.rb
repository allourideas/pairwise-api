class AddAlgorithmToAppearance < ActiveRecord::Migration
  def self.up
    add_column :appearances, :algorithm, :string
  end

  def self.down
    remove_column :appearances, :algorithm
  end
end
