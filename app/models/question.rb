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
  has_many :skips
  has_many :densities
  has_many :appearances
 
  #comment out to run bt import script! 
  after_save :ensure_at_least_two_choices
  attr_accessor :ideas
    
  def item_count
    choices_count
  end
   
  def choose_prompt(options = {})

	  if self.uses_catchup? || options[:algorithm] == "catchup"
	      logger.info("Question #{self.id} is using catchup algorithm!")
	      next_prompt = self.pop_prompt_queue
	      if next_prompt.nil?
		      logger.info("DEBUG Catchup prompt cache miss! Nothing in prompt_queue")
		      next_prompt = self.catchup_choose_prompt
		      record_prompt_cache_miss
	      else
		      record_prompt_cache_hit
	      end
	      self.send_later :add_prompt_to_queue
	      return next_prompt
	  else
	      #Standard choose prompt at random
              next_prompt = self.picked_prompt
	      return next_prompt
	  end
          
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
	   weighted.each do |item, weight| 
		   weighted[item] = weight/sum 
		   weighted[item] = 0.0 unless weighted[item].finite?
	   end
   elsif weighted.instance_of?(Array)
	   sum = weighted.inject(0) {|sum, item| sum += item}
	   weighted.each_with_index do |item, i| 
		   weighted[i] = item/sum
		   weighted[i] = 0.0 unless weighted[i].finite?
	   end

   end
  end

 def bradley_terry_probs
   probs = []
   prev_probs = []

   fuzz = 0.001

   # What ordering key we use is unimportant, just need a consistent way to link index of prob to id
   the_choices = self.choices.sort{|x,y| x.id<=>y.id}

   # This hash is keyed by pairs of choices - 'LC.id, RC.id'
   the_prompts = prompts_hash_by_choice_ids

   # Initial probabilities chosen at random
   the_choices.size.times do 
	   probs << rand
	   prev_probs << rand
   end

   t=0
   probs_size = probs.size

   difference = 1
   
   # probably want to add a fuzz here to account for floating rounding
   while difference > fuzz do
      s = t % probs_size
      prev_probs = probs.dup
      choice = the_choices[s]

      numerator = choice.wins.to_f



      denominator = 0.0
      the_choices.each_with_index do |c, index|
	      if(index == s)
		      next
	      end

	      wins_and_losses = the_prompts["#{choice.id}, #{c.id}"].votes.size + the_prompts["#{c.id}, #{choice.id}"].votes.size

	      denominator+= (wins_and_losses).to_f / (prev_probs[s] + prev_probs[index])
      end
      probs[s] = numerator / denominator 
      # avoid divide by zero NaN
      probs[s] = 0.0 unless probs[s].finite?
      normalize!(probs)
      t+=1

      difference = 0
      probs.each_with_index do |curr, index|
	      difference += (curr - prev_probs[index]).abs
      end
      puts difference
   end
 
   probs_hash = {}
   probs.each_with_index do |item, index| 
	   probs_hash[the_choices[index].id] = item
   end
   probs_hash
 end

 
 def all_bt_scores
	 btprobs = bradley_terry_probs
	 btprobs.each do |key, value|
		 c = Choice.find(key)
		 puts "#{c.id}: #{c.votes.size} #{c.compute_bt_score(btprobs)}"
	 end

 end

 def prompts_hash_by_choice_ids
   the_prompts = {}
   self.prompts.each do |p|
      the_prompts["#{p.left_choice_id}, #{p.right_choice_id}"] = p
   end
   the_prompts
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

      seed_seed_sum = 0
      seed_seed_total = 0

      seed_nonseed_sum= 0
      seed_nonseed_total= 0

      nonseed_seed_sum= 0
      nonseed_seed_total= 0
      
      nonseed_nonseed_sum= 0
      nonseed_nonseed_total= 0

      #the_prompts = prompts.find(:all, :include => ['left_choice', 'right_choice'])
      prompts.find_each(:include => ['left_choice', 'right_choice']) do |p|
	      if p.left_choice.user_created == false && p.right_choice.user_created == false
		      seed_seed_sum += p.appearances.size
		      seed_seed_total +=1
	      elsif p.left_choice.user_created == false && p.right_choice.user_created == true
		      seed_nonseed_sum += p.appearances.size
		      seed_nonseed_total +=1
	      elsif p.left_choice.user_created == true && p.right_choice.user_created == false
		      nonseed_seed_sum += p.appearances.size
		      nonseed_seed_total +=1
	      elsif p.left_choice.user_created == true && p.right_choice.user_created == true
		      nonseed_nonseed_sum += p.appearances.size
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

  def pq_key
	  @pq_key ||= "#{self.id}_prompt_queue"
  end

  def clear_prompt_queue
	  $redis.del(self.pq_key)
  end

  def add_prompt_to_queue
	  prompt = self.catchup_choose_prompt
	  $redis.rpush(self.pq_key, prompt.id)
	  prompt
  end

  def pop_prompt_queue
	  prompt_id = $redis.lpop(self.pq_key)
	  prompt = prompt_id.nil? ? nil : Prompt.find(prompt_id.to_i)
  end

  def record_prompt_cache_miss
	  $redis.incr(self.pq_key + "_" + Time.now.to_date.to_s + "_"+ "misses")
	  $redis.expire(self.pq_key, 24*60*60 * 3) #Expire in three days
  end

  def record_prompt_cache_hit
	  $redis.incr(self.pq_key + "_" + Time.now.to_date.to_s + "_"+ "hits")
	  $redis.expire(self.pq_key, 24*60*60 * 3) #Expire in three days
  end

  def get_prompt_cache_misses(date)
	  $redis.get(self.pq_key + "_" + date.to_s + "_"+ "misses")
  end
  def get_prompt_cache_hits(date)
	  $redis.get(self.pq_key + "_" + date.to_s + "_"+ "hits")
  end

  def export_and_delete(type, options={})
	  delete_at = options.delete(:delete_at)
	  filename = export(type, options)

	  File.send_at(delete_at, :delete, filename)
	  filename
  end

  def export(type, options = {})

    case type
    when 'votes'
	 outfile = "ideamarketplace_#{self.id}_votes.csv"

	 headers = ['Vote ID', 'Session ID', 'Question ID','Winner ID', 'Winner Text', 'Loser ID', 'Loser Text',
		    'Prompt ID', 'Left Choice ID', 'Right Choice ID', 'Created at', 'Updated at',  'Appearance ID',
		    'Response Time (s)', 'Session Identifier']
    
    when 'ideas'
	 outfile = "ideamarketplace_#{self.id}_ideas.csv"
         headers = ['Ideamarketplace ID','Idea ID', 'Idea Text', 'Wins', 'Losses', 'Times involved in Cant Decide', 'Score',
	       'User Submitted', 'Session ID', 'Created at', 'Last Activity', 'Active',  
		'Appearances on Left', 'Appearances on Right']
    when 'non_votes'
         outfile = "ideamarketplace_#{self.id}_non_votes.csv"
         headers = ['Record Type', 'Record ID', 'Session ID', 'Question ID','Left Choice ID', 'Left Choice Text', 
	            'Right Choice ID', 'Right Choice Text', 'Prompt ID', 'Appearance ID', 'Reason',
		    'Created at', 'Updated at', 'Response Time (s)', 'Session Identifier']
    else 
	 raise "Unsupported export type: #{type}"
    end

    filename = File.join(File.expand_path(Rails.root), "public", "system", "exports", 
			 self.id.to_s, Digest::SHA1.hexdigest(outfile + rand(10000000).to_s) + "_" + outfile)

    FileUtils::mkdir_p(File.dirname(filename))
    csv_data = FasterCSV.open(filename, "w") do |csv|
       csv << headers	

       case type
       when 'votes'

         self.votes.find_each(:include => [:prompt, :choice, :loser_choice, :voter]) do |v|
	       prompt = v.prompt
	       # these may not exist
	       loser_data = v.loser_choice.nil? ? "" : "'#{v.loser_choice.data.strip}'"
	       left_id = v.prompt.nil? ? "" : v.prompt.left_choice_id
	       right_id = v.prompt.nil? ? "" : v.prompt.right_choice_id

	       csv << [ v.id, v.voter_id, v.question_id, v.choice_id, "'#{v.choice.data.strip}'", v.loser_choice_id, loser_data,
		       v.prompt_id, left_id, right_id, v.created_at, v.updated_at, v.appearance_id,
		       v.time_viewed.to_f / 1000.0 , v.voter.identifier] 
	 end

       when 'ideas'
         self.choices.each do |c|
             user_submitted = c.user_created ? "TRUE" : "FALSE"
	     left_prompts_ids = c.prompts_on_the_left.ids_only
	     right_prompts_ids = c.prompts_on_the_right.ids_only

	     left_appearances = self.appearances.count(:conditions => {:prompt_id => left_prompts_ids})
	     right_appearances = self.appearances.count(:conditions => {:prompt_id => right_prompts_ids})

	     num_skips = self.skips.count(:conditions => {:prompt_id => left_prompts_ids + right_prompts_ids})

	       csv << [c.question_id, c.id, "'#{c.data.strip}'", c.wins, c.losses, num_skips, c.score,
		       user_submitted , c.item.creator_id, c.created_at, c.updated_at, c.active,
		       left_appearances, right_appearances]
         end
       when 'non_votes'
	       
	  self.appearances.find_each(:include => [:skip, :vote, :voter]) do |a|
		  # we only display skips and orphaned appearances in this csv file
		  unless a.vote.nil?
			  next
		  end
		  
		  #If no skip and no vote, this is an orphaned appearance
		  if a.skip.nil?
	              prompt = a.prompt
	              csv << [ "Orphaned Appearance", a.id, a.voter_id, a.question_id, a.prompt.left_choice.id, a.prompt.left_choice.data.strip, 
		           a.prompt.right_choice.id, a.prompt.right_choice.data.strip, a.prompt_id, 'N/A', 'N/A',
		           a.created_at, a.updated_at, 'N/A', a.voter.identifier] 
			  
		  else
	          #If this appearance belongs to a skip, show information on the skip instead
		      s = a.skip
	              prompt = s.prompt
	              csv << [ "Skip", s.id, s.skipper_id, s.question_id, s.prompt.left_choice.id, s.prompt.left_choice.data.strip, 
		           s.prompt.right_choice.id, s.prompt.right_choice.data.strip, s.prompt_id, s.appearance_id, s.skip_reason,
		           s.created_at, s.updated_at, s.time_viewed.to_f / 1000.0 , s.skipper.identifier] 
		  end
	  end
       end

    end

    if options[:response_type] == 'redis'

	    if options[:redis_key].nil?
		    raise "No :redis_key specified"
	    end
	    #The client should use blpop to listen for a key
	    #The client is responsible for deleting the redis key (auto expiration results failure in testing)
	    $redis.lpush(options[:redis_key], filename)
    #TODO implement response_type == 'email' for use by customers of the API (not local)
    end

    filename
  end



end
