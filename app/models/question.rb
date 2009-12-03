class Question < ActiveRecord::Base
  belongs_to :creator, :class_name => "Visitor", :foreign_key => "creator_id"
  belongs_to :site, :class_name => "User", :foreign_key => "site_id"
  
  has_many :choices, :order => 'score DESC'
  has_many :prompts do
    def pick(algorithm = nil)
      if algorithm
        algorithm.pick_from(self) #todo
      else
        lambda {prompts[rand(prompts.size-1)]}.call
      end
    end
  end
  has_many :votes, :as => :voteable 
  
  after_save :ensure_at_least_two_choices
  attr_accessor :ideas
    
  def item_count
    choice_count
  end
  
  def prompt_count
    Prompt.count(:all, :conditions => {:question_id => id})
  end

   def choice_count
     Choice.count(:all, :conditions => {:question_id => id})
   end

   def votes_count
     Vote.count(:all, :conditions => {:voteable_id => id, :voteable_type => 'Question'})
   end
   
   def picked_prompt
     prompts[rand(prompts.count-1)]#Prompt.find(picked_prompt_id)
   end
   
   def picked_prompt_id
     lambda {@picked ||= prompts(true)[rand(prompts.count-1)].id}.call

     lambda { prompts(true)[rand(prompts.count-1)].id }.call
   end
   
   def left_choice_text(prompt = nil)
     prompt ||= prompts.first#prompts.pick
     picked_prompt.left_choice.item.data
   end

   def right_choice_text(prompt = nil)
     prompt ||= prompts.first
     picked_prompt.right_choice.item.data
   end

   def self.voted_on_by(u)
     select {|z| z.voted_on_by_user?(u)}
   end

   def voted_on_by_user?(u)
     u.questions_voted_on.include? self
   end

   
  
  validates_presence_of :site, :on => :create, :message => "can't be blank"
  validates_presence_of :creator, :on => :create, :message => "can't be blank"
  
  def ensure_at_least_two_choices
    the_ideas = (self.ideas.blank? || self.ideas.empty?) ? ['sample idea 1', 'sample idea 2'] : self.ideas.lines
    if self.choices.empty?
      the_ideas.each { |choice_text|
        item = Item.create!({:data => choice_text, :creator => creator})
        puts item.inspect
        choice = choices.create!(:item => item, :creator => creator)
        puts choice.inspect
      }
    end
  end

end
#@site = User.create!(:email => 'pius+7@alum.mit.edu', :password => 'password', :password_confirmation => 'password')
#@site.questions.create!(:name => 'what do you want?', :creator => @site.default_visitor)
