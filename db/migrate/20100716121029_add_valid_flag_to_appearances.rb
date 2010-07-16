class AddValidFlagToAppearances < ActiveRecord::Migration
  def self.up
     add_column :appearances, :valid_record, :boolean, :default => true
     add_column :appearances, :validity_information, :string
  end

  def self.down
     remove_column :appearances, :valid_record
     remove_column :appearances, :validity_information
  end
end
