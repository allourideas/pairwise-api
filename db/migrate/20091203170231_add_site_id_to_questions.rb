class AddSiteIdToQuestions < ActiveRecord::Migration
  def self.up
    add_column :questions, :site_id, :integer
  end

  def self.down
    remove_column :questions, :site_id
  end
end
