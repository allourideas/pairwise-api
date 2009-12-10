class AddBloomToQuestions < ActiveRecord::Migration
  def self.up
    add_column :questions, :bloom, :text
  end

  def self.down
    remove_column :questions, :bloom
  end
end
