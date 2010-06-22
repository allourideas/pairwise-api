class AddCreatorToChoices < ActiveRecord::Migration
  def self.up
	add_column :choices, :creator_id, :integer
	Choice.find(:all, :include => [:item]).each do |c|
	  c.creator_id = c.item.creator_id
	  c.save
	end
  end

  def self.down
	remove_column :choices, :creator_id
  end
end
