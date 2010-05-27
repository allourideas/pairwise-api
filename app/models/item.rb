class Item < ActiveRecord::Base
  belongs_to :question, :counter_cache => true
  belongs_to :site, :class_name => "User", :foreign_key => "site_id"
  belongs_to :creator, :class_name => "Visitor", :foreign_key => "creator_id"
  
  named_scope :active, :conditions => { :active => true }
  named_scope :with_creator_ids, lambda { |*args| {:conditions => {:creator_id=> args.first }} }
  
  # has_many :items_questions, :dependent => :destroy
  # has_many :questions, :through => :items_questions
  # has_and_belongs_to_many :prompts
  # 
  #   has_and_belongs_to_many :votes
  #   has_and_belongs_to_many :prompt_requests

  validates_presence_of :creator_id
  validates_presence_of :data, :on => :create, :message => "can't be blank"
  
  def self.mass_insert!(creator_id, data_array)
    #alpha
    inserts = data_array.collect{|i| "(#{connection.quote i}, #{connection.quote creator_id})"}.join(", ")
    connection.insert("INSERT INTO items(data, creator_id) VALUES (#{inserts})")
  end
end
