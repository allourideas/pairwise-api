class CreatePrompts < ActiveRecord::Migration
  def self.up
    create_table "prompts", :force => true do |t|
      t.integer  "algorithm_id"
      t.integer  "question_id"
      t.integer  "left_choice_id"
      t.integer  "right_choice_id"
      t.integer  "voter_id"
      t.boolean  "active"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "tracking"
    end

  end

  def self.down
    drop_table :prompts
  end
end
