class CreateItems < ActiveRecord::Migration
  def self.up
    create_table "items", :force => true do |t|
      t.text     "data"
      t.boolean  "active"
      t.text     "tracking"
      t.integer  "creator_id"
      t.integer  "voter_id"
      t.integer "site_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

  end

  def self.down
    drop_table :items
  end
end
