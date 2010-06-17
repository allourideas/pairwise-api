class MakeCatchupDefault < ActiveRecord::Migration
  def self.up
	change_column :questions, :uses_catchup, :boolean, :default => true
  end

  def self.down
	change_column :questions, :uses_catchup, :boolean, :default => false
  end
end
