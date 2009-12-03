class Item < ActiveRecord::Base
  belongs_to :question, :counter_cache => true
  belongs_to :site, :class_name => "User", :foreign_key => "site_id"
  belongs_to :creator, :class_name => "Visitor", :foreign_key => "creator_id"
  
  named_scope :active, :conditions => { :active => true }
  
  # has_many :items_questions, :dependent => :destroy
  # has_many :questions, :through => :items_questions
  # has_and_belongs_to_many :prompts
  # 
  #   has_and_belongs_to_many :votes
  #   has_and_belongs_to_many :prompt_requests

  validates_presence_of :creator_id
  validates_presence_of :data, :on => :create, :message => "can't be blank"
end
