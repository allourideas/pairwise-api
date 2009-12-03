class CreateChoices < ActiveRecord::Migration
  def self.up
    create_table "choices", :force => true do |t|
      t.integer  "item_id"
      t.integer  "question_id"
      t.integer  "position"
      t.integer  "wins"
      t.integer  "ratings"
      t.integer  "losses"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "request_id"
      t.integer  "prompt_id"
      t.boolean  "active",      :default => false
      t.text     "tracking"
      t.float    "score"
    end

  end

  def self.down
    drop_table :choices
  end
end
