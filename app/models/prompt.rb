class Prompt < ActiveRecord::Base
  #has_many :choices, :order => 'position DESC'

  has_many :skips
  has_many :votes
  has_many :appearances
  
  
  belongs_to :question, :counter_cache => true
  belongs_to :left_choice, :class_name => "Choice", :foreign_key => "left_choice_id", :counter_cache => :prompts_on_the_left_count
  belongs_to :right_choice, :class_name => "Choice", :foreign_key => "right_choice_id", :counter_cache => :prompts_on_the_right_count
  
  validates_presence_of :left_choice, :on => :create, :message => "can't be blank"
  validates_presence_of :right_choice, :on => :create, :message => "can't be blank"

  named_scope :with_left_choice, lambda { |*args| {:conditions => ["left_choice_id = ?", (args.first.id)]} }
  named_scope :with_right_choice, lambda { |*args| {:conditions => ["right_choice_id = ?", (args.first.id)]} }
  named_scope :with_choice, lambda { |*args| {:conditions => ["(right_choice_id = ?) OR (left_choice_id = ?)", (args.first.id)]} }
  named_scope :with_choice_id, lambda { |*args| {:conditions => ["(right_choice_id = ?) OR (left_choice_id = ?)", (args.first)]} }
  #named_scope :voted_on_by, :include => :choices, :conditions => 
  #named_scope :voted_on_by, proc {|u| { :conditions => { :methodology => methodology } } }
  
  named_scope :active, :include => [:left_choice, :right_choice], :conditions => { 'left_choice.active' => true, 'right_choice.active' => true }
  named_scope :ids_only, :select => 'id'
  
  attr_protected :votes_count, :left_choice_id, :right_choice_id
  attr_readonly :question_id

  # Algorithm used to select this prompt.
  #
  # This is not saved to the prompt table and only lives as long as this prompt
  # instance. We use this to save the algorithm to the appearances table.
  attr_accessor :algorithm

  def self.voted_on_by(u)
    select {|z| z.voted_on_by_user?(u)}
  end
  
  
  def choices
    [left_choice, right_choice]
  end
  
  def voted_on_by_user?(u)
    u.voted_for?(left_choice) || u.voted_for?(right_choice)
  end
  
  def left_choice_text(prompt = nil)
    left_choice.data
  end
  
  def active?
    left_choice.active? and right_choice.active?
  end
  
  
  def right_choice_text(prompt = nil)
    right_choice.data
  end

  def as_json(options={})
    hash = super(options)
    hash['prompt'].merge!(options[:merge]) if options.has_key? :merge
    return hash
  end
  
end
