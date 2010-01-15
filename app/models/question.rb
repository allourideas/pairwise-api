class Question < ActiveRecord::Base
  require 'set'
  extend ActiveSupport::Memoizable
  
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
   
 #TODO: generalize for prompts of rank > 2
 #TODO: add index for rapid finding
 def picked_prompt(rank = 2)
   logger.info "inside Question#picked_prompt"
   raise NotImplementedError.new("Sorry, we currently only support pairwise prompts.  Rank of the prompt must be 2.") unless rank == 2
   begin
     choice_id_array = distinct_array_of_choice_ids(rank)
     @p ||= prompts.find_or_create_by_left_choice_id_and_right_choice_id(choice_id_array[0], choice_id_array[1], :include => [{ :left_choice => :item }, { :right_choice => :item }])
     logger.info "#{@p.inspect} is active? #{@p.active?}"
   end until @p.active?
   return @p
 end
 memoize :picked_prompt
   
   def distinct_array_of_choice_ids(rank = 2, only_active = true)
     @choice_ids = choice_ids
     @s = @choice_ids.size
     begin
       first_one, second_one = rand(@s), rand(@s)
       @the_choice_ids = Set.new(@choice_ids.values_at(first_one, second_one))
       # @the_choice_ids << choices.active.first(:order => 'RAND()', :select => 'id').id
       # @the_choice_ids << choices.active.last(:order => 'RAND()', :select => 'id').id
     end until (@the_choice_ids.size == rank) 
     logger.info "set populated and looks like #{@the_choice_ids.inspect}"
     return @the_choice_ids.to_a
   end
 
   def picked_prompt_id
     picked_prompt.id
   end
 
   def left_choice_text(prompt = nil)
     picked_prompt.left_choice.item.data
   end

   def right_choice_text(prompt = nil)
     picked_prompt.right_choice.item.data
   end

   def self.voted_on_by(u)
     select {|z| z.voted_on_by_user?(u)}
   end

   def voted_on_by_user?(u)
     u.questions_voted_on.include? self
   end
   
   def should_autoactivate_ideas?
     it_should_autoactivate_ideas?
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
