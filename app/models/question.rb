class Question < ActiveRecord::Base
  acts_as_versioned
  
  require 'set'
  include Utility
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

  attr_accessor :ideas
  after_create :create_choices_from_ideas

  attr_protected :votes_count, :inactive_choices_count, :choices_count,
                 :active_items_count, :prompts_count

  attr_readonly :site_id

  # regenerate prompts if cache is less than this full
  # ideally this prevents active marketplaces from
  # regenerating prompts too frequently
  @@percent_full = 0.9
  @@num_prompts = 1000

  named_scope :created_by, lambda { |id|
    {:conditions => { :local_identifier => id } }
  }

  def create_choices_from_ideas
    if ideas && ideas.any?
      ideas.each do |idea|
        # all but last is considered part of batch create, so the
        # last one will fire things that only need to be run at the end
        choices.create!(:creator => self.creator, :active => true, :data => idea.squish.strip, :part_of_batch_create => idea != ideas.last, :question => self)
      end
    end
  end
    
  def item_count
    choices.size
  end

  # returns array of hashes where each has has voter_id and total keys
  def votes_per_session
    self.votes.find(:all, :select => 'voter_id, count(*) as total', :group => :voter_id).map { |v| {:voter_id => v.voter_id, :total => v.total.to_i} }
  end

  def median_votes_per_session
    totals = self.votes_per_session.map { |v| v[:total] }
    return median(totals)
  end

  def choose_prompt(options = {})

          # if there is one or fewer active choices, we won't be able to find a prompt
    if self.choices.size - self.inactive_choices_count <= 1 
      raise RuntimeError, "More than one choice needs to be active"
    end

    if self.uses_catchup? || options[:algorithm] == "catchup"
        logger.info("Question #{self.id} is using catchup algorithm!")
        next_prompt = self.pop_prompt_queue
        if next_prompt.nil?
          logger.info("DEBUG Catchup prompt cache miss! Nothing in prompt_queue")
          next_prompt = self.simple_random_choose_prompt
          record_prompt_cache_miss
        else
          record_prompt_cache_hit
        end
        self.delay.add_prompt_to_queue
        return next_prompt
    else
        #Standard choose prompt at random
        return self.simple_random_choose_prompt
    end
          
  end

  #TODO: generalize for prompts of rank > 2
  def simple_random_choose_prompt(rank = 2)
    logger.info "inside Question#simple_random_choose_prompt"
    raise NotImplementedError.new("Sorry, we currently only support pairwise prompts.  Rank of the prompt must be 2.") unless rank == 2
    choice_id_array = distinct_array_of_choice_ids(:rank => rank, :only_active => true)
    prompt = prompts.find_or_initialize_by_left_choice_id_and_right_choice_id(choice_id_array[0], choice_id_array[1])
    prompt.save
    prompt
  end

  # adapted from ruby cookbook(2006): section 5-11
  def catchup_choose_prompt(num=1000)
    weighted = catchup_prompts_weights
    # Rand returns a number from 0 - 1, so weighted needs to be normalized
    generated_prompts = []

    num.times do
      prompt = nil
      until prompt && prompt.active?
        target = rand 
        left_choice_id = right_choice_id = nil

        weighted.each do |item, weight|
          if target <= weight
            left_choice_id, right_choice_id = item.split(", ")
            break
          end
          target -= weight
        end
        prompt = prompts.find_or_initialize_by_left_choice_id_and_right_choice_id(left_choice_id, right_choice_id)
        prompt.save
      end
      generated_prompts.push prompt
    end
    generated_prompts
  end


  def catchup_prompts_weights
    weights = Hash.new(0)
    throttle_min = 0.05
    sum = 0.0

    # get weights of all existing prompts that have two active choices
    active_choices = choices.active
    active_choice_ids = active_choices.map {|c| c.id}
    sql = "SELECT votes_count, left_choice_id, right_choice_id FROM prompts WHERE question_id = #{self.id} AND left_choice_id IN (#{active_choice_ids.join(',')}) AND right_choice_id IN (#{active_choice_ids.join(',')})"
    # Warning: lots of memory possibly used here
    # We don't want to use Rails find_each or find_in_batches because
    # it is too slow for close to a million rows.  We don't need ActiveRecord
    # objects here.  It may be a good idea to update this to grab these in
    # batches.
    ActiveRecord::Base.connection.select_all(sql).each do |p|
      value = [(1.0/ (p['votes_count'].to_i + 1).to_f).to_f, throttle_min].min
      weights[p['left_choice_id'].to_s+", "+p['right_choice_id'].to_s] = value
      sum += value
    end

    # This will not run once all prompts have been generated, 
    #  but it prevents us from having to pregenerate all possible prompts
    if weights.size < active_choices.size ** 2 - active_choices.size
      active_choices.each do |l|
        active_choices.each do |r|
          if l.id == r.id
            next
          end
          if !weights.has_key?("#{l.id}, #{r.id}")
            weights["#{l.id}, #{r.id}"] = throttle_min
            sum+=throttle_min
          end
        end
      end
    end

    normalize!(weights, sum)
    weights
  end

  def get_optional_information(params)

    return {} if params.nil?

    result = {}
    visitor_identifier = params[:visitor_identifier]
    current_user = self.site

    if params[:with_prompt]
     
      if params[:with_appearance] && visitor_identifier.present?
        visitor = current_user.visitors.find_or_create_by_identifier(visitor_identifier)

        last_appearance = get_first_unanswered_appearance(visitor)

        if last_appearance.nil?
          @prompt = choose_prompt(:algorithm => params[:algorithm])
          @appearance = current_user.record_appearance(visitor, @prompt)
        else
        #only display a new prompt and new appearance if the old prompt has not been voted on
          @appearance = last_appearance
          @prompt= @appearance.prompt
        end

        if params[:future_prompts]
          num_future = params[:future_prompts][:number].to_i rescue 1
          num_future.times do |number|
            offset = number + 1
            last_appearance = get_first_unanswered_appearance(visitor, offset)
            if last_appearance.nil?
              @future_prompt = choose_prompt(:algorithm => params[:algorithm])
              @future_appearance = current_user.record_appearance(visitor, @future_prompt)
            else
              @future_appearance = last_appearance
              @future_prompt= @future_appearance.prompt
            end

            result.merge!({"future_appearance_id_#{offset}".to_sym => @future_appearance.lookup})
            result.merge!({"future_prompt_id_#{offset}".to_sym => @future_prompt.id})

            ["left", "right"].each do |side|
              ["text", "id"].each do |param|
                choice = (side == "left") ? @future_prompt.left_choice : @future_prompt.right_choice
                param_val = (param == "text") ? choice.data : choice.id
  
              result.merge!({"future_#{side}_choice_#{param}_#{offset}".to_sym => param_val})
              end
            end

          end

        end

        result.merge!({:appearance_id => @appearance.lookup})
      else
        # throw some error
      end 
    
      if !@prompt 
        @prompt = choose_prompt(:algorithm => params[:algorithm])
      end
      result.merge!({:picked_prompt_id => @prompt.id})
    end 

    if params[:with_visitor_stats]
      visitor = current_user.visitors.find_or_create_by_identifier(visitor_identifier)
      result.merge!(:visitor_votes => Vote.find_without_default_scope(:all, :conditions => {:voter_id => visitor, :question_id => self.id}).length)
      result.merge!(:visitor_ideas => visitor.choices.count)
    end
   
    # this might get cpu intensive if used too often. If so, store the calculated value in redis
    #   and expire after X minutes
    if params[:with_average_votes]
      votes_by_visitors = self.votes.count(:group => 'voter_id')
      
      if votes_by_visitors.size > 0
        average = votes_by_visitors.inject(0){|total, (k,v)| total = total + v}.to_f / votes_by_visitors.size.to_f
      else
        average = 0.0
      end

      result.merge!(:average_votes => average.round) # round to 2 decimals
    end

    return result
  end

  #passing precomputed sum saves us a traversal through the array
  def normalize!(weighted, sum=nil)
    if weighted.instance_of?(Hash)
      if sum.nil?
        sum = weighted.inject(0) do |sum, item_and_weight|
          sum += item_and_weight[1]
        end
        sum = sum.to_f
      end
      weighted.each do |item, weight| 
        weighted[item] = weight/sum 
        weighted[item] = 0.0 unless weighted[item].finite?
      end
    elsif weighted.instance_of?(Array)
      sum = weighted.inject(0) {|sum, item| sum += item} if sum.nil?
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

   
  def distinct_array_of_choice_ids(params={})
    params = {
      :rank => 2,
      :only_active => true
    }.merge(params)
    rank = params[:rank]
    only_active = params[:only_active]
    count = (only_active) ? choices.active.count : choices.count
    
    found_choices = []
    # select only active choices?
    conditions = (only_active) ? ['active = ?', true] : ['1=1']

    rank.times do 
      # if we've already found some, make sure we don't find them again
      if found_choices.count > 0
        conditions[0] += ' AND id NOT IN (?)'
        conditions.push found_choices
      end
    
      found_choices.push choices.find(:first,
          :select => 'id',
          :conditions => conditions,
          # rand generates value >= 0 and < param
          :offset => rand(count - found_choices.count)).id
    end
    return found_choices
  end
 
   def picked_prompt_id
     simple_random_choose_prompt.id
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

      #cache some hashes to prevent tons of sql thrashing
      num_appearances_by_prompt = self.appearances.count(:group => :prompt_id)


      is_user_created = {}
      self.choices.each do |c|
        is_user_created[c.id] = c.user_created
      end


      #the_prompts = prompts.find(:all, :include => ['left_choice', 'right_choice'])
      prompts.find_each do |p|

        num_appearances = num_appearances_by_prompt[p.id]

        if num_appearances.nil?
          num_appearances = 0
        end

        left_user_created = is_user_created[p.left_choice_id]
        right_user_created = is_user_created[p.right_choice_id]


        if left_user_created == false && right_user_created == false
          seed_seed_sum += num_appearances
          seed_seed_total +=1
        elsif left_user_created == false && right_user_created == true
          seed_nonseed_sum += num_appearances
          seed_nonseed_total +=1
        elsif left_user_created == true && right_user_created == false
          nonseed_seed_sum += num_appearances
          nonseed_seed_total +=1
        elsif left_user_created == true && right_user_created == true
          nonseed_nonseed_sum += num_appearances
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

  
  # make prompt queue less than @@precent_full
  def mark_prompt_queue_for_refill
    # 2 because redis starts indexes at 0
    new_size = (@@num_prompts * @@percent_full - 2).floor
    $redis.ltrim(self.pq_key, 0, new_size)
  end

  def add_prompt_to_queue
    # if less than 90% full, regenerate prompts
    # we skip generating prompts if more than 90% full to
    # prevent one busy marketplace for ruling the queue
    if $redis.llen(self.pq_key) < @@num_prompts * @@percent_full
      prompts = self.catchup_choose_prompt(@@num_prompts)
      # clear list
      $redis.ltrim(self.pq_key, 0, 0)
      $redis.lpop(self.pq_key)
      prompts.each do |prompt|
        $redis.rpush(self.pq_key, prompt.id)
      end
      return prompts
    end
  end

  def pop_prompt_queue
    begin
       prompt_id = $redis.lpop(self.pq_key)
       prompt = prompt_id.nil? ? nil : Prompt.find(prompt_id.to_i)
          end until (prompt.nil? || prompt.active?)
          prompt
  end

  def record_prompt_cache_miss
    $redis.incr(self.pq_key + "_" + Time.now.to_date.to_s + "_"+ "misses")
  end

  def record_prompt_cache_hit
    $redis.incr(self.pq_key + "_" + Time.now.to_date.to_s + "_"+ "hits")
  end

  def get_prompt_cache_misses(date)
    $redis.get(self.pq_key + "_" + date.to_s + "_"+ "misses")
  end
  def get_prompt_cache_hits(date)
    $redis.get(self.pq_key + "_" + date.to_s + "_"+ "hits")
  end

  def reset_cache_tracking_keys(date)
    $redis.del(self.pq_key + "_" + date.to_s + "_"+ "misses")
    $redis.del(self.pq_key + "_" + date.to_s + "_"+ "hits")
  end


  def expire_prompt_cache_tracking_keys(date, expire_time = 24*60*60 * 3) # default expires in three days
    $redis.expire(self.pq_key + "_" + date.to_s + "_"+ "hits", expire_time)
    $redis.expire(self.pq_key + "_" + date.to_s + "_"+ "misses", expire_time)
  end


  def export(type, options = {})

    case type
      when 'votes'
        outfile = "ideamarketplace_#{self.id}_votes"

        headers = ['Vote ID', 'Session ID', 'Ideamarketplace ID','Winner ID', 'Winner Text', 'Loser ID', 'Loser Text', 'Prompt ID', 'Left Choice ID', 'Right Choice ID', 'Created at', 'Updated at',  'Response Time (s)', 'Missing Response Time Explanation', 'Session Identifier', 'Valid']
    
      when 'ideas'
        outfile = "ideamarketplace_#{self.id}_ideas"
        headers = ['Ideamarketplace ID','Idea ID', 'Idea Text', 'Wins', 'Losses', 'Times involved in Cant Decide', 'Score', 'User Submitted', 'Session ID', 'Created at', 'Last Activity', 'Active', 'Appearances on Left', 'Appearances on Right', 'Session Identifier']
      when 'non_votes'
        outfile = "ideamarketplace_#{self.id}_non_votes"
        headers = ['Record Type', 'Record ID', 'Session ID', 'Ideamarketplace ID','Left Choice ID', 'Left Choice Text', 'Right Choice ID', 'Right Choice Text', 'Prompt ID', 'Reason', 'Created at', 'Updated at', 'Response Time (s)', 'Missing Response Time Explanation', 'Session Identifier', 'Valid']
      else 
        raise "Unsupported export type: #{type}"
    end

    csv_data = FasterCSV.generate do |csv|
      csv << headers 
      case type
        when 'votes'

          Vote.find_each_without_default_scope(:conditions => {:question_id => self}, :include => [:prompt, :choice, :loser_choice, :voter]) do |v|
            valid = v.valid_record ? "TRUE" : "FALSE"
            prompt = v.prompt
            # these may not exist
            loser_data = v.loser_choice.nil? ? "" : v.loser_choice.data.strip
            left_id = v.prompt.nil? ? "" : v.prompt.left_choice_id
            right_id = v.prompt.nil? ? "" : v.prompt.right_choice_id

            time_viewed = v.time_viewed.nil? ? "NA": v.time_viewed.to_f / 1000.0

            csv << [ v.id, v.voter_id, v.question_id, v.choice_id, v.choice.data.strip, v.loser_choice_id, loser_data,
            v.prompt_id, left_id, right_id, v.created_at, v.updated_at,
            time_viewed, v.missing_response_time_exp , v.voter.identifier, valid] 
          end

        when 'ideas'
          self.choices.each do |c|
            user_submitted = c.user_created ? "TRUE" : "FALSE"
            active         = c.active ? "TRUE" : "FALSE"
            left_prompts_ids = c.prompts_on_the_left.ids_only
            right_prompts_ids = c.prompts_on_the_right.ids_only

            left_appearances = self.appearances.count(:conditions => {:prompt_id => left_prompts_ids})
            right_appearances = self.appearances.count(:conditions => {:prompt_id => right_prompts_ids})

            num_skips = self.skips.count(:conditions => {:prompt_id => left_prompts_ids + right_prompts_ids})

            csv << [c.question_id, c.id, c.data.strip, c.wins, c.losses, num_skips, c.score, user_submitted , c.creator_id, c.created_at, c.updated_at, active, left_appearances, right_appearances, c.creator.identifier]

          end
        when 'non_votes'
         
          self.appearances.find_each(:include => [:voter], :conditions => ['answerable_type <> ? OR answerable_type IS NULL', 'Vote']) do |a|
      
          if a.answerable_type == 'Skip'
            # If this appearance belongs to a skip, show information on the skip instead
            s = a.answerable
            valid = s.valid_record ? 'TRUE' : 'FALSE'
            time_viewed = s.time_viewed.nil? ? "NA": s.time_viewed.to_f / 1000.0
            prompt = s.prompt
            csv << [ "Skip", s.id, s.skipper_id, s.question_id, s.prompt.left_choice.id, s.prompt.left_choice.data.strip, s.prompt.right_choice.id, s.prompt.right_choice.data.strip, s.prompt_id, s.skip_reason, s.created_at, s.updated_at, time_viewed , s.missing_response_time_exp, s.skipper.identifier,valid] 
        
          else
            # If no skip and no vote, this is an orphaned appearance
            prompt = a.prompt
            action_appearances = Appearance.count(:conditions =>
              ["voter_id = ? AND question_id = ? AND answerable_type IS NOT ?",
                a.voter_id, a.question_id, nil])
            appearance_type = (action_appearances > 0) ? 'Stopped_Voting_Or_Skipping' : 'Bounce'
            csv << [ appearance_type, a.id, a.voter_id, a.question_id, a.prompt.left_choice.id, a.prompt.left_choice.data.strip, a.prompt.right_choice.id, a.prompt.right_choice.data.strip, a.prompt_id, 'NA', a.created_at, a.updated_at, 'NA', '', a.voter.identifier, 'TRUE'] 
          end
        end
      end

    end


    if options[:response_type] == 'redis'
      # let's compress this for redis
      # it should get removed from redis relatively quickly
      zlib = Zlib::Deflate.new
      zlibcsv = zlib.deflate(csv_data, Zlib::FINISH)
      zlib.close

      if options[:redis_key].nil?
        raise "No :redis_key specified"
      end
      #The client should use blpop to listen for a key
      #The client is responsible for deleting the redis key (auto expiration results failure in testing)
      $redis.lpush(options[:redis_key], zlibcsv)
    else
      return csv_data
    end
  end

  def get_first_unanswered_appearance(visitor, offset=0)
       last_appearance = visitor.appearances.find(:first, 
              :conditions => {:question_id => self.id,
                        :answerable_id => nil
                                   },
              :order => 'id ASC',
              :offset => offset)
       if last_appearance && !last_appearance.prompt.active?
      last_appearance.valid_record = false
      last_appearance.validity_information = "Deactivated Prompt"
      last_appearance.save

      return get_first_unanswered_appearance(visitor)
       end
       last_appearance
  end

  def votes_per_uploaded_choice(only_active=false)
    if only_active
      uploaded_choices_count = choices.active.not_created_by(creator_id).count
    else
      uploaded_choices_count = choices.not_created_by(creator_id).count
    end
    return nil if uploaded_choices_count == 0
    votes.count.to_f / uploaded_choices_count.to_f
  end

  # a response is either a vote or a skip, get the median per session
  def median_responses_per_session
    median(Question.connection.select_values("
      SELECT COUNT(*) total FROM (
        (SELECT voter_id   vid FROM votes WHERE question_id = #{id})
        UNION ALL
        (SELECT skipper_id vid FROM skips WHERE question_id = #{id})
      ) b GROUP BY b.vid ORDER BY total
    ").map{|i| i.to_i}, true) || nil
  end

  def upload_to_participation_rate
    swp = sessions_with_participation
    return nil if swp == 0
    sessions_with_uploaded_ideas.to_f / swp.to_f
  end

  # total number of sessions that have uploaded an idea
  def sessions_with_uploaded_ideas
    choices.find(:all,
      :conditions => ["creator_id <> ?", creator_id],
      :group => :creator_id
    ).count
  end

  # total sessions with at least one vote, skip, or uploaded idea
  def sessions_with_participation
    # only select votes that are valid because wikipedia project has new votes
    # marked as invalid and we want that to be effectively closed to updating this value.
    Question.connection.select_one("
      SELECT COUNT(*) FROM (
        (SELECT DISTINCT(skipper_id) vid FROM skips WHERE question_id = #{id})
        UNION
        (SELECT DISTINCT(voter_id) vid FROM votes WHERE question_id = #{id} AND valid_record = 1)
        UNION
        (SELECT DISTINCT(creator_id) vid FROM choices WHERE question_id = #{id})
      ) AS t WHERE vid <> #{creator_id}
    ").values.first
  end

  def vote_rate
    tus = total_uniq_sessions
    return nil if tus == 0
    sessions_with_vote.to_f / tus.to_f
  end

  def total_uniq_sessions
    appearances.count(:select => "DISTINCT(voter_id)")
  end

  # total number of sessions with at least one vote
  def sessions_with_vote
    Question.connection.select_one("
      SELECT COUNT(DISTINCT(voter_id)) FROM votes WHERE votes.question_id = #{self.id}
    ").values.first
  end

end
