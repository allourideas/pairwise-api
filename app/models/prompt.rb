class Prompt < ActiveRecord::Base
  #has_many :choices, :order => 'position DESC'

  has_many :skips
  has_many :votes, :as => :voteable
  
  
  belongs_to :question, :counter_cache => true
  belongs_to :left_choice, :class_name => "Choice", :foreign_key => "left_choice_id", :counter_cache => true
  belongs_to :right_choice, :class_name => "Choice", :foreign_key => "right_choice_id", :counter_cache => true
  
  named_scope :with_left_choice, lambda { |*args| {:conditions => ["left_choice_id = ?", (args.first.id)]} }
  named_scope :with_right_choice, lambda { |*args| {:conditions => ["right_choice_id = ?", (args.first.id)]} }
  named_scope :with_choice, lambda { |*args| {:conditions => ["(right_choice_id = ?) OR (left_choice_id = ?)", (args.first.id)]} }
  named_scope :with_choice_id, lambda { |*args| {:conditions => ["(right_choice_id = ?) OR (left_choice_id = ?)", (args.first)]} }
  #named_scope :voted_on_by, :include => :choices, :conditions => 
  #named_scope :voted_on_by, proc {|u| { :conditions => { :methodology => methodology } } }
  
  def self.voted_on_by(u)
    select {|z| z.voted_on_by_user?(u)}
  end
  
  
  named_scope :visible, :include => :category, :conditions => { 'categories.hidden' => false }
  
  validates_presence_of :left_choice, :on => :create, :message => "can't be blank"
  validates_presence_of :right_choice, :on => :create, :message => "can't be blank"
  
  def choices
    [left_choice, right_choice]
  end
  
  def voted_on_by_user?(u)
    u.voted_for?(left_choice) || u.voted_for?(right_choice)
  end
  
  def left_choice_text(prompt = nil)
    left_choice.item.data
  end
  
  def left_choice_id
    left_choice.id
  end
  
  def right_choice_id
    right_choice.id
  end
    
  
  def right_choice_text(prompt = nil)
    right_choice.item.data
  end
  
end
