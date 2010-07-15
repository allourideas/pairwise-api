class AddPolymorphicAnswerableToAppearance < ActiveRecord::Migration
  def self.up
     add_column :appearances, :answerable_id, :integer
     add_column :appearances, :answerable_type, :string
  end

  def self.down
     remove_column :appearances, :answerable_id
     remove_column :appearances, :answerable_type
  end
end
