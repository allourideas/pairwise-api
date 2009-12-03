class AddLocalIdentifierToQuestions < ActiveRecord::Migration
  def self.up
    add_column :questions, :local_identifier, :string
  end

  def self.down
    remove_column :questions, :local_identifier
  end
end
