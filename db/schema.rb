# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110124211740) do

  create_table "appearances", :force => true do |t|
    t.integer  "voter_id"
    t.integer  "site_id"
    t.integer  "prompt_id"
    t.integer  "question_id"
    t.string   "lookup"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "answerable_id"
    t.string   "answerable_type"
    t.boolean  "valid_record",         :default => true
    t.string   "validity_information"
  end

  add_index "appearances", ["lookup"], :name => "index_appearances_on_lookup"
  add_index "appearances", ["question_id", "voter_id"], :name => "index_appearances_on_question_id_voter_id"

  create_table "choices", :force => true do |t|
    t.integer  "item_id"
    t.integer  "question_id"
    t.integer  "position"
    t.integer  "ratings"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "request_id"
    t.integer  "prompt_id"
    t.boolean  "active",                     :default => false
    t.text     "tracking"
    t.float    "score"
    t.string   "local_identifier"
    t.integer  "prompts_on_the_left_count",  :default => 0
    t.integer  "prompts_on_the_right_count", :default => 0
    t.integer  "wins",                       :default => 0
    t.integer  "losses",                     :default => 0
    t.integer  "prompts_count",              :default => 0
    t.string   "data"
    t.integer  "creator_id"
  end

  add_index "choices", ["creator_id"], :name => "index_choices_on_creator_id"
  add_index "choices", ["question_id", "score"], :name => "index_choices_on_question_id_and_score"

  create_table "clicks", :force => true do |t|
    t.integer  "site_id"
    t.integer  "visitor_id"
    t.text     "additional_info"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "what_was_clicked"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.string   "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "densities", :force => true do |t|
    t.integer  "question_id"
    t.float    "value"
    t.string   "prompt_type", :default => ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "flags", :force => true do |t|
    t.string   "explanation", :default => ""
    t.integer  "visitor_id"
    t.integer  "choice_id"
    t.integer  "question_id"
    t.integer  "site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "old_items", :force => true do |t|
    t.text     "data"
    t.boolean  "active"
    t.text     "tracking"
    t.integer  "creator_id"
    t.integer  "voter_id"
    t.integer  "site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "question_id"
  end

  add_index "old_items", ["creator_id"], :name => "index_items_on_creator_id"

  create_table "oldskips", :force => true do |t|
    t.integer  "skipper_id"
    t.integer  "prompt_id"
    t.text     "tracking"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "oldvotes", :force => true do |t|
    t.text     "tracking"
    t.integer  "site_id"
    t.integer  "voter_id"
    t.integer  "voteable_id"
    t.string   "voteable_type", :default => ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "prompts", :force => true do |t|
    t.integer  "question_id"
    t.integer  "left_choice_id"
    t.integer  "right_choice_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "tracking"
    t.integer  "votes_count",     :default => 0
  end

  add_index "prompts", ["left_choice_id", "right_choice_id", "question_id"], :name => "a_cool_index", :unique => true
  add_index "prompts", ["left_choice_id"], :name => "index_prompts_on_left_choice_id"
  add_index "prompts", ["question_id"], :name => "index_prompts_on_question_id"
  add_index "prompts", ["right_choice_id"], :name => "index_prompts_on_right_choice_id"

  create_table "questions", :force => true do |t|
    t.integer  "creator_id"
    t.string   "name",                         :default => ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "choices_count",                :default => 0
    t.integer  "prompts_count",                :default => 0
    t.boolean  "active",                       :default => false
    t.text     "tracking"
    t.text     "information"
    t.integer  "site_id"
    t.string   "local_identifier"
    t.integer  "votes_count",                  :default => 0
    t.boolean  "it_should_autoactivate_ideas", :default => false
    t.integer  "inactive_choices_count",       :default => 0
    t.boolean  "uses_catchup",                 :default => true
    t.boolean  "show_results",                 :default => true
  end

  create_table "skips", :force => true do |t|
    t.text     "tracking"
    t.integer  "site_id"
    t.integer  "skipper_id"
    t.integer  "question_id"
    t.integer  "prompt_id"
    t.integer  "appearance_id"
    t.integer  "time_viewed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "skip_reason"
    t.string   "missing_response_time_exp", :default => ""
    t.boolean  "valid_record",              :default => true
    t.string   "validity_information"
  end

  add_index "skips", ["prompt_id"], :name => "index_skips_on_prompt_id"
  add_index "skips", ["question_id"], :name => "index_skips_on_question_id"

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "encrypted_password", :limit => 128
    t.string   "salt",               :limit => 128
    t.string   "confirmation_token", :limit => 128
    t.string   "remember_token",     :limit => 128
    t.boolean  "email_confirmed",                   :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["id", "confirmation_token"], :name => "index_users_on_id_and_confirmation_token"
  add_index "users", ["remember_token"], :name => "index_users_on_remember_token"

  create_table "visitors", :force => true do |t|
    t.integer  "site_id"
    t.string   "identifier", :default => ""
    t.text     "tracking"
    t.boolean  "activated"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "visitors", ["identifier", "site_id"], :name => "index_visitors_on_identifier_and_site_id", :unique => true

  create_table "votes", :force => true do |t|
    t.text     "tracking"
    t.integer  "site_id"
    t.integer  "voter_id"
    t.integer  "question_id"
    t.integer  "prompt_id"
    t.integer  "choice_id"
    t.integer  "loser_choice_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "time_viewed"
    t.integer  "appearance_id"
    t.string   "missing_response_time_exp", :default => ""
    t.boolean  "valid_record",              :default => true
    t.string   "validity_information"
  end

  add_index "votes", ["choice_id"], :name => "choice_id_idx"
  add_index "votes", ["loser_choice_id"], :name => "loser_choice_id_idx"
  add_index "votes", ["question_id"], :name => "question_id_idx"
  add_index "votes", ["voter_id"], :name => "index_votes_on_voter_id"

end
