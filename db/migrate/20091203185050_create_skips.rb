class CreateSkips < ActiveRecord::Migration
  def self.up
    create_table "skips", :force => true do |t|
      t.integer  "skipper_id"
      t.integer  "prompt_id"
      t.text     "tracking"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

  end

  def self.down
    drop_table :skips
  end
end
