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
  has_many :densities
 
  #comment out to run bt import script! 
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
 def catchup_choose_prompt
   weighted = catchup_prompts_weights
   # Rand returns a number from 0 - 1, so weighted needs to be normalized
   prompt = nil

   until prompt && prompt.active?
	   target = rand 
	   prompt_id = nil

	   weighted.each do |item, weight|
		   if target <= weight
			   prompt_id = item
			   break
		   end
		   target -= weight
	   end
	   prompt = Prompt.find(prompt_id, :include => ['left_choice', 'right_choice'])
   end
   # check if prompt has two active choices here, maybe we can set this on the prompt level too?
   prompt
 end


 # TODO Add index for question id on prompts table
 def catchup_prompts_weights
   weights = Hash.new(0)
   throttle_min = 0.05
   #assuming all prompts exist

   #the_prompts = prompts.find(:all, :select => 'id, votes_count')
   #We don't really need to instantiate all the objects
   the_prompts = ActiveRecord::Base.connection.select_all("SELECT id, votes_count from prompts where question_id =#{self.id}")

   the_prompts.each do |p|
	   weights[p["id"].to_i] = [(1.0/ (p["votes_count"].to_i + 1).to_f).to_f, throttle_min].min
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

  def density
      # slow code, only to be run by cron job once at night
      the_prompts = prompts.find(:all, :include => ['left_choice', 'right_choice'])

      seed_seed_sum = 0
      seed_seed_total = 0

      seed_nonseed_sum= 0
      seed_nonseed_total= 0

      nonseed_seed_sum= 0
      nonseed_seed_total= 0
      
      nonseed_nonseed_sum= 0
      nonseed_nonseed_total= 0

      the_prompts.each do |p|
	      if p.left_choice.user_created == false && p.right_choice.user_created == false
		      seed_seed_sum += p.votes.size
		      seed_seed_total +=1
	      elsif p.left_choice.user_created == false && p.right_choice.user_created == true
		      seed_nonseed_sum += p.votes.size
		      seed_nonseed_total +=1
	      elsif p.left_choice.user_created == true && p.right_choice.user_created == false
		      nonseed_seed_sum += p.votes.size
		      nonseed_seed_total +=1
	      elsif p.left_choice.user_created == true && p.right_choice.user_created == true
		      nonseed_nonseed_sum += p.votes.size
		      nonseed_nonseed_total +=1
	      end
      end

      densities = {}
      densities[:seed_seed] = seed_seed_sum.to_f / seed_seed_total.to_f
      densities[:seed_nonseed] = seed_nonseed_sum.to_f / seed_nonseed_total.to_f
      densities[:nonseed_seed] = nonseed_seed_sum.to_f / nonseed_seed_total.to_f
      densities[:nonseed_nonseed] = nonseed_nonseed_sum.to_f / nonseed_nonseed_total.to_f
      
      puts "Seed_seed sum: #{seed_seed_sum}, seed_seed total num: #{seed_seed_total}"
      puts "Seed_nonseed sum: #{seed_nonseed_sum}, seed_nonseed total num: #{seed_nonseed_total}"
      puts "Nonseed_seed sum: #{nonseed_seed_sum}, nonseed_seed total num: #{nonseed_seed_total}"
      puts "Nonseed_nonseed sum: #{nonseed_nonseed_sum}, nonseed_nonseed total num: #{nonseed_nonseed_total}"


      densities
  end

  def save_densities!

	  d_hash = density

	  d_hash.each do |type, average|
		  d = Density.new
		  d.question_id = self.id
		  d.prompt_type = type.to_s
		  d.value = average.nan? ? nil : average
		  d.save!
	  end
  end



end
