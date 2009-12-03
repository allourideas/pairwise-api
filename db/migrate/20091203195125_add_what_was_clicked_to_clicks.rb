class AddWhatWasClickedToClicks < ActiveRecord::Migration
  def self.up
    add_column :clicks, :what_was_clicked, :string
  end

  def self.down
    remove_column :clicks, :what_was_clicked
  end
end
