class AddVersionToChoice < ActiveRecord::Migration
  def self.up
    # if you want to manually run the query to create
    # all the initial versions in choice_versions table set this to true
    run_query_manually = false
    # default of 1 so all existing rows have a version of 1
    add_column :choices, :version, :integer, :default => 1
    # make version nil by default
    change_column :choices, :version, :integer, :default => nil
    Choice.create_versioned_table
    query = "INSERT INTO choice_versions (SELECT null, id, version, item_id, question_id, position, ratings, created_at, updated_at, request_id, prompt_id, active, tracking, score, local_identifier, prompts_on_the_left_count, prompts_on_the_right_count, wins, losses, prompts_count, data, creator_id FROM choices)"
    if run_query_manually
      puts "!!!!!!!!!!!!!!!"
      puts "RUN THIS QUERY:"
      puts "!!!!!!!!!!!!!!!"
      puts ""
      puts query
      puts ""
    else
      Choice.connection.execute(query)
    end
  end

  def self.down
    remove_column :choices, :version
    Choice.drop_versioned_table
  end
end
