class AddVersionToQuestion < ActiveRecord::Migration
  def self.up
    # set default to one because we're going to create
    # versions for all the existing data.
    add_column :questions, :version, :integer, :default => 1
    Question.create_versioned_table
    Question.find(:all).each do |q|
      attributes = q.attributes
      attributes[q.versioned_foreign_key] = attributes.delete("id")
      Question::Version.create(attributes)
    end
    # make version nil by default after we've created initial versions
    change_column :questions, :version, :integer, :default => nil
  end

  def self.down
    remove_column :questions, :version
    Question.drop_versioned_table
  end
end
