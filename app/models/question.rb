class Question < ActiveRecord::Base
  require 'set'
  extend ActiveSupport::Memoizable
  
  belongs_to :creator, :class_name => "Visitor", :foreign_key => "creator_id"
  belongs_to :site, :class_name => "User", :foreign_key => "site_id"
  
  has_many :choices, :order => 'score DESC'
  has_many :prompts do
    def pick(algorithm = nil)
      logger.info( "inside Question#prompts#pick - never called?")
      if algorithm
        algorithm.pick_from(self) #todo
      else
        lambda {prompts[rand(prompts.size-1)]}.call
      end
    end
  end
  has_many :votes
  
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
     @p = prompts.find_or_create_by_left_choice_id_and_right_choice_id(choice_id_array[0], choice_id_array[1], :include => [{ :left_choice => :item }, { :right_choice => :item }])
     logger.info "#{@p.inspect} is active? #{@p.active?}"
   end until @p.active?
   return @p
 end
 
 # adapted from ruby cookbook(2006): section 5-11
 def catchup_choose_prompt_id
   weighted = catchup_prompts_weights
   # Rand returns a number from 0 - 1, so weighted needs to be normalized
   target = rand 
   weighted.each do |item, weight|
	return item if target <= weight
        target -= weight
   end
   # check if prompt has two active choices here, maybe we can set this on the prompt level too?
 end


 # TODO Add index for question id on prompts table
 def catchup_prompts_weights
   weights = Hash.new(0)
   throttle_min = 0.05
   #assuming all prompts exist
   prompts.each do |p|
	   weights[p.id] = [(1.0/ (p.votes.size + 1).to_f).to_f, throttle_min].min
   end
   normalize!(weights)
   weights
 end

 def normalize!(weighted)
   if weighted.instance_of?(Hash)
	   sum = weighted.inject(0) do |sum, item_and_weight|
	      sum += item_and_weight[1]
	   end
	   sum = sum.to_f
	   weighted.each { |item, weight| weighted[item] = weight/sum }
   elsif weighted.instance_of?(Array)
	   sum = weighted.inject(0) {|sum, item| sum += item}
	   weighted.each_with_index {|item, i| weighted[i] = item/sum}
   end
  end
   
   def distinct_array_of_choice_ids(rank = 2, only_active = true)
     @choice_ids = choice_ids
     @s = @choice_ids.size
     begin
       index_list = (0...@s).sort_by{rand}
       first_one, second_one = index_list.first, index_list.second
       @the_choice_ids = @choice_ids.values_at(first_one, second_one)
       # @the_choice_ids << choices.active.first(:order => 'RAND()', :select => 'id').id
       # @the_choice_ids << choices.active.last(:order => 'RAND()', :select => 'id').id
     end until (@the_choice_ids.size == rank) 
     logger.info "List populated and looks like #{@the_choice_ids.inspect}"
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
        choice = choices.create!(:item => item, :creator => creator, :active => true, :data => choice_text)
        puts choice.inspect
      }
    end
  end

end
