class AddLocalIdentifierToChoices < ActiveRecord::Migration
  def self.up
    add_column :choices, :local_identifier, :string
  end

  def self.down
    remove_column :choices, :local_identifier
  end
end
