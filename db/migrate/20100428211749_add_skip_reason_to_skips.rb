class AddSkipReasonToSkips < ActiveRecord::Migration
  def self.up
	  add_column :skips, :skip_reason, :string
  end

  def self.down
	  drop_column :skips, :skip_reason
  end
end
