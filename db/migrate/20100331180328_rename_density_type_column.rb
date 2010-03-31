class RenameDensityTypeColumn < ActiveRecord::Migration
  def self.up
	  rename_column :densities, :type, :prompt_type
  end

  def self.down
	  rename_column :denisities, :prompt_type, :type
  end
end
