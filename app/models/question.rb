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
    choices_count
  end

   def picked_prompt
     pc = self.prompts_count < 1 ? 2 : self.prompts_count
     begin
       @p = prompts.find(rand(pc-1) + prompts.first.id)
     end until @p.active?
     return @p
   end
   
 
   def picked_prompt_id
     pc = self.prompts_count < 1 ? 2 : self.prompts_count
     begin
       @i = rand(pc-1) + prompts.first.id #try caching this first prompt value at some point
     end until prompts.find(@i).active?
     return @i
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
    the_ideas = (self.ideas.blank? || self.ideas.empty?) ? ['sample idea 1', 'sample idea 2'] : self.ideas
    the_ideas << 'sample choice' if the_ideas.length < 2
    if self.choices.empty?
      the_ideas.each { |choice_text|
        item = Item.create!({:data => choice_text, :creator => creator})
        puts item.inspect
        choice = choices.create!(:item => item, :creator => creator, :active => true)
        puts choice.inspect
      }
    end
  end

end
