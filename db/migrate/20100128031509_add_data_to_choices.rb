class AddDataToChoices < ActiveRecord::Migration
  def self.up
    add_column :choices, :data, :string
    puts "copying existing item data into associated choices ..."
    Choice.all.each {|c| c.data = c.item.data; c.save!}
  end

  def self.down
    remove_column :choices, :data
  end
end
