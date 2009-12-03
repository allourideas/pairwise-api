class CreateQuestions < ActiveRecord::Migration
  def self.up
    create_table "questions", :force => true do |t|
      t.integer  "creator_id"
      t.string   "name",                      :default => ""
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "items_count",               :default => 0
      t.integer  "active_items_count",        :default => 0
      t.integer  "choices_count",             :default => 0
      t.integer  "prompts_count",             :default => 0
      t.boolean  "active",                    :default => false
      t.text     "tracking"
      t.integer  "first_prompt_algorithm_id"
      t.text     "information"
    end

  end

  def self.down
    drop_table :questions
  end
end
