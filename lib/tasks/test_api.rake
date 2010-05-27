require 'fastercsv'
namespace :test_api do

   task :all => [:question_vote_consistency,:generate_density_information]

   desc "Don't run unless you know what you are doing"
   task(:generate_lots_of_votes => :environment) do
      if Rails.env.production?
	 print "You probably don't want to run this in production as it will falsify a bunch of random votes"
      end
 
 
     current_user = User.first
      3000.times do 
	      question = Question.find(120) # test question change as needed
	      @p = Prompt.find(question.catchup_choose_prompt_id)

	      current_user.record_vote("test_vote", @p, rand(2))
      end

   end

   desc "Generate appearances for any votes that have no current appearance, should only need to be run once"
   task(:generate_appearances_for_existing_votes => :environment) do 
	   votes = Vote.all

	   count = 0 
	   votes.each do |v|
		   if v.appearance.nil?
			   print "."
			   a = Appearance.create(:voter_id => v.voter_id, :site_id => v.site_id, :prompt_id => v.prompt_id, :question_id => v.question_id, :created_at => v.created_at, :updated_at => v.updated_at)
			   v.appearance = a
			   v.save

			   count += 1
		   end
	   end

	   print count
   end


   desc "Generate past density information"
   task(:generate_past_densities => :environment) do 
	   #this is not elegant, but should only be run once, so quick and dirty wins

	   start_date = Vote.find(:all, :conditions => 'loser_choice_id IS NOT NULL', :order => :created_at, :limit =>  1).first.created_at.to_date
	   start_date.upto(Date.today) do |the_date|
		   questions = Question.find(:all, :conditions => ['created_at < ?', the_date])

		   print the_date.to_s
		   questions.each do |q|
			   puts q.id
			   relevant_choices = q.choices.find(:all, :conditions => ['created_at < ?', the_date])

			   seed_choices = 0

			   if relevant_choices == 0
				   next
				   #this question had not been created yet
			   end

			   relevant_choices.each do |c|
				   if !c.user_created
					   seed_choices+=1
				   end

			   end

			   nonseed_choices = relevant_choices.size - seed_choices

			   seed_seed_total = seed_choices **2 - seed_choices
			   nonseed_nonseed_total = nonseed_choices **2 - nonseed_choices
			   seed_nonseed_total = seed_choices * nonseed_choices
			   nonseed_seed_total = seed_choices * nonseed_choices

			   seed_seed_sum = 0
			   seed_nonseed_sum= 0
			   nonseed_seed_sum= 0
			   nonseed_nonseed_sum= 0

			   q.appearances.find_each(:conditions => ['prompt_id IS NOT NULL AND created_at < ?', the_date]) do |a|

				   p = a.prompt
				   if p.left_choice.user_created == false && p.right_choice.user_created == false
					   seed_seed_sum += 1
				   elsif p.left_choice.user_created == false && p.right_choice.user_created == true
					   seed_nonseed_sum += 1
				   elsif p.left_choice.user_created == true && p.right_choice.user_created == false
					   nonseed_seed_sum += 1
				   elsif p.left_choice.user_created == true && p.right_choice.user_created == true
					   nonseed_nonseed_sum += 1
				   end
			   end

			   densities = {}
			   densities[:seed_seed] = seed_seed_sum.to_f / seed_seed_total.to_f
			   densities[:seed_nonseed] = seed_nonseed_sum.to_f / seed_nonseed_total.to_f
			   densities[:nonseed_seed] = nonseed_seed_sum.to_f / nonseed_seed_total.to_f
			   densities[:nonseed_nonseed] = nonseed_nonseed_sum.to_f / nonseed_nonseed_total.to_f

			   densities.each do |type, average|
				   d = Density.new
				   d.created_at = the_date
				   d.question_id = q.id
				   d.prompt_type = type.to_s
				   d.value = average.nan? ? nil : average
				   d.save!
			   end

			   puts "Seed_seed sum: #{seed_seed_sum}, seed_seed total num: #{seed_seed_total}"
			   puts "Seed_nonseed sum: #{seed_nonseed_sum}, seed_nonseed total num: #{seed_nonseed_total}"
			   puts "Nonseed_seed sum: #{nonseed_seed_sum}, nonseed_seed total num: #{nonseed_seed_total}"
			   puts "Nonseed_nonseed sum: #{nonseed_nonseed_sum}, nonseed_nonseed total num: #{nonseed_nonseed_total}"


		   end

	   end

   end


   desc "Should only need to be run once"
   task(:generate_all_possible_prompts => :environment) do
      Question.find(:all).each do |q|
	choices = q.choices
	if q.prompts.size > choices.size**2 - choices.size
		print "ERROR: #{q.id}\n"
		next
	elsif q.prompts.size == choices.size**2 - choices.size
		print "#{q.id} has enough prompts, skipping...\n"
		next
	else
		print "#{q.id} should add #{(choices.size ** 2 - choices.size) - q.prompts.size}\n"

	end
        created_timestring = q.created_at.to_s(:db)
	updated_timestring = Time.now.to_s(:db) #isn't rails awesome?
	promptscount=0
        inserts = []
  	the_prompts = Prompt.find(:all, :select => 'id, left_choice_id, right_choice_id', :conditions => {:question_id => q.id})

	the_prompts_hash = {}
	the_prompts.each do |p|
		the_prompts_hash["#{p.left_choice_id},#{p.right_choice_id}"] = 1
	end

        choices.each do |l|
	   choices.each do |r|
	     if l.id == r.id
		   next
	     else
		#p = the_prompts.find{|o| o.left_choice_id == l.id && o.right_choice_id == r.id}
		keystring = "#{l.id},#{r.id}"
		p = the_prompts_hash[keystring]
		if p.nil?
	           inserts.push("(NULL, #{q.id}, NULL, #{l.id}, '#{created_timestring}', '#{updated_timestring}', NULL, 0, #{r.id}, NULL, NULL)")
		   promptscount+=1
		end

	     end

	   end
         end

	print "Added #{promptscount} to #{q.id}\n"
	sql = "INSERT INTO `prompts` (`algorithm_id`, `question_id`, `voter_id`, `left_choice_id`, `created_at`, `updated_at`, `tracking`, `votes_count`, `right_choice_id`, `active`, `randomkey`) VALUES #{inserts.join(', ')}"
	unless inserts.empty?
		ActiveRecord::Base.connection.execute(sql)
	end

	Question.update_counters(q.id, :prompts_count => promptscount)


       end


   
   end


   desc "Dump votes of a question by left vs right id"
   task(:make_csv => :environment) do

	   q = Question.find(120)

	   the_prompts = q.prompts_hash_by_choice_ids

	   #hash_of_choice_ids_from_left_to_right_to_votes
	   the_hash = {}
	   the_prompts.each do |key, p|
		   left_id, right_id = key.split(", ")
		   if not the_hash.has_key?(left_id)
			   the_hash[left_id] = {}
			   the_hash[left_id][left_id] = 0
		   end

		   the_hash[left_id][right_id] = p.votes.size
	   end

	   the_hash.sort.each do |xval, row|
		   rowarray = []
		   row.sort.each do |yval, cell|
			   rowarray << cell
		   end
		   puts rowarray.join(", ")
	   end
   end


   desc "Generate density information for each question - should be run nightly"
   task(:generate_density_information => :environment) do

	   # calculating densities is expensive, so only do it for questions with new data
	   question_ids = Vote.count(:conditions => ['date(created_at) = ?', Date.yesterday], :group => 'question_id').keys()

	   Question.find(:all, :conditions => {:id => question_ids}).each do |q|
		   q.save_densities!
	   end

	   # we can just copy the previous night's data for remaining questions
	   
	   Question.find(:all, :conditions => ['id NOT IN (?)', question_ids]).each do |q|
		   densities = q.densities.find(:all, :conditions => ['date(created_at) = ?', Date.yesterday])


		   densities.each do |d|
			   new_d = d.clone
			   new_d.created_at = new_d.updated_at = Time.now
			   new_d.save!
		   end

		   if densities.blank?
			   #fallback in case there wasn't a successful run yesterday
			   q.save_densities!
			   
		   end

	   end
   end
      
   desc "Description here"
   task(:question_vote_consistency => :environment) do
      questions = Question.find(:all)
      errors = []
      successes = []

      questions.each do |question|

	message, error_occurred = check_basic_balanced_stats(question)
        #hack for now, get around to doing this with block /yield to get rid of duplication
        if error_occurred
	   errors << message
        else
	   successes << message
        end


        message, error_occurred = check_each_choice_appears_within_n_stddevs(question)
        if error_occurred
	   errors << message
        else
	   successes << message
        end
        
	message, error_occurred = check_each_choice_equally_likely_to_appear_left_or_right(question)
        if error_occurred
	   errors << message
        else
	   successes << message
        end
	
	
			
	message, error_occurred = check_object_counter_cache_values_match_actual_values(question)
        if error_occurred
	   errors << message
        else
	   successes << message
        end


	#catchup specific 
	if question.uses_catchup?
	     message, error_occurred = check_prompt_cache_hit_rate(question)
             if error_occurred
	        errors << message
             else
	        successes << message
             end
	end
     end

     message, error_occurred = ensure_all_votes_and_skips_have_unique_appearance
     
     if error_occurred
	errors << message
     else
	successes << message
     end

     message, error_occurred = response_time_tests	

     if error_occurred
	errors << message
     else
	successes << message
     end

     email_text = "Conducted the following tests on API data and found the following results\n" +
			 "For each of the #{questions.length} questions in the database: \n"
     errors.each do |e|
	email_text += "     Test FAILED: " + e + "\n"
     end

     successes.uniq.each do |s|
	s.split("\n").each do |m| # some successes have several lines
	   email_text += "     Test Passed: " + m + "\n"
	end
     end
	 
     puts email_text
     
     if errors.empty?
	CronMailer.deliver_info_message(CRON_EMAIL, "Test of API Vote Consistency passed", email_text)
     else
     	CronMailer.deliver_info_message("#{CRON_EMAIL},#{ERRORS_EMAIL}", "Error! Failure of API Vote Consistency " , email_text)
     end

   end
   def check_basic_balanced_stats(question)
	error_message = ""
	success_message = "2 x Total Wins = Total Votes\n" +
			 "Total Votes (wins + losses) is Even\n" +
			 "Total Votes (wins + losses) = 2 x the number of vote objects that belong to the question\n" +
		         "Total generated prompts on left = Total generated prompts on right"
	total_wins =0
	total_votes =0
	total_generated_prompts_on_left = 0
	total_generated_prompts_on_right = 0
	total_scores_gte_fifty= 0
	total_scores_lte_fifty= 0
	error_bool = false

	question.choices.each do |choice|
			
	    if choice.wins
	      total_wins += choice.wins
	      total_votes += choice.wins
	    end

	    if choice.losses
              total_votes += choice.losses
	    end

	    total_generated_prompts_on_left += choice.prompts_on_the_left.size
	    total_generated_prompts_on_right += choice.prompts_on_the_right.size

	    cached_score = choice.score.to_f
	    generated_score = choice.compute_score.to_f

	    delta = 0.001

	    if (cached_score - generated_score).abs >= delta
		 error_message += "Error! The cached_score is not equal to the calculated score for choice #{choice.id}"

		 print "This score is wrong! #{choice.id} , Question ID: #{question.id}, #{cached_score}, #{generated_score}, updated: #{choice.updated_at}\n"


	    end

	    if cached_score == 0.0 || cached_score == 100.0 || cached_score.nil?
		 error_message += "Error! The cached_score for choice #{choice.id} is exactly 0 or 100, the value: #{cached_score}"
		 print "Either 0 or 100 This score is wrong! #{choice.id} , Question ID: #{question.id}, #{cached_score}, #{generated_score}, updated: #{choice.updated_at}\n"
	    end


	    if cached_score >= 50
		    total_scores_gte_fifty +=1
	    end
	    if cached_score <= 50
		    total_scores_lte_fifty +=1
	    end


        end
	
	if (2*total_wins != total_votes)
		 error_message += "Error 1: 2 x Total Wins != Total votes"
		 error_bool= true
	end

	if(total_votes % 2 != 0)
		error_message += "Error 2: Total votes is not Even!"
		error_bool= true
	end

	if(total_votes != 2* question.votes_count)
		error_message += "Error 3: Total votes != 2 x # vote objects"
		error_bool = true
	end

	if(total_generated_prompts_on_right != total_generated_prompts_on_right)
		error_message += "Error 4: Total generated prompts on left != Total generated prompts on right"
		error_bool = true
	end

	if(total_scores_lte_fifty == question.choices.size || total_scores_gte_fifty == question.choices.size) && (total_scores_lte_fifty != total_scores_gte_fifty)
		error_message += "Error: The scores of all choices are either all above 50, or all below 50. This is probably wrong"
		error_bool = true
		puts "Error score fifty: #{question.id}"
	end
	
	if error_bool
	   error_message += "Question #{question.id}: 2*wins = #{2*total_wins}, total votes = #{total_votes}, vote_count = #{question.votes_count}\n"
	end
        return error_message.blank? ? [success_message, false] : [error_message, true] 
   end
   def check_each_choice_appears_within_n_stddevs(question)
	error_message =""
	success_message = "Each choice has appeared n times, where n falls within 6 stddevs of the mean number of appearances for a question " +
			 "(Note: this applies only to seed choices (not user submitted) and choices currently marked active)"

	wins_by_choice_id = question.votes.active.count(:group => :choice_id)
	losses_by_choice_id= question.votes.active.count(:conditions => "loser_choice_id IS NOT NULL", :group => :loser_choice_id)

	#Rails returns an ordered hash, which doesn't allow for blocks to change merging logic.
	#A little hack to create a normal hash
	wins_hash = {}
	wins_hash.merge!(wins_by_choice_id)
	losses_hash = {}
	losses_hash.merge!(losses_by_choice_id)



	appearances_by_choice_id = wins_hash.merge(losses_hash) do |key, oldval, newval| oldval + newval end

	sum = total_appearances = appearances_by_choice_id.values.inject(0) {|sum, x| sum +=x}
	mean = average_appearances = total_appearances.to_f / appearances_by_choice_id.size.to_f

	if sum > 0:
	   stddev = Math.sqrt( appearances_by_choice_id.values.inject(0) { |sum, e| sum + (e - mean) ** 2 } / appearances_by_choice_id.size.to_f )

           appearances_by_choice_id.each do |choice_id, n_i| 
		if (n_i < (mean - 6*stddev)) || (n_i > mean + 6 *stddev)
			error_message += "Choice #{choice_id} in Question ##{question.id} has an irregular number of appearances: #{n_i}, as compared to the mean: #{mean} and stddev #{stddev} for this question"
		end
	   end
	end

        return error_message.blank? ? [success_message, false] : [error_message, true] 
   end
   def check_each_choice_equally_likely_to_appear_left_or_right(question)
   	error_message = ""
	success_message = "All choices have equal probability of appearing on left or right (within error params)"
	question.choices.each do |c|
	         left_prompts_ids = c.prompts_on_the_left.ids_only
	         right_prompts_ids = c.prompts_on_the_right.ids_only

	         left_appearances = question.appearances.count(:conditions => {:prompt_id => left_prompts_ids})
	         right_appearances = question.appearances.count(:conditions => {:prompt_id => right_prompts_ids})

		 n = left_appearances + right_appearances

		 if n == 0
		    next
		 end
		 est_p = right_appearances.to_f / n.to_f
		 z = (est_p - 0.5).abs / Math.sqrt((0.5 * 0.5) / n.to_f)

		 if z > 6 
		 	error_message += "Error: Choice ID #{c.id} seems to favor one side: Left Appearances #{left_appearances}, Right Appearances: #{right_appearances}, z = #{z}\n"
		 end
	end
        return error_message.blank? ? [success_message, false] : [error_message, true] 
   end
   def check_prompt_cache_hit_rate(question)
	error_message = ""
	success_message = "At least 90% of prompts on catchup algorithm questions were served from cache\n" 

	misses = question.get_prompt_cache_misses(Date.yesterday).to_i
	hits = question.get_prompt_cache_hits(Date.yesterday).to_i

	question.expire_prompt_cache_tracking_keys(Date.yesterday)
		
	yesterday_votes = question.appearances.count(:conditions => ['date(created_at) = ?', Date.yesterday])

	if misses + hits != yesterday_votes
	     error_message += "Error! Question #{question.id} isn't tracking prompt cache hits and misses accurately! Expected #{yesterday_votes}, Actual: #{misses+hits}\n"
	end

	miss_rate = misses.to_f / yesterday_votes.to_f
	if miss_rate > 0.1
	     error_message += "Error! Question #{question.id} has less than 90% of appearances taken from a pre-generated cache! Expected <#{0.1}, Actual: #{miss_rate}\n"
	end
        return error_message.blank? ? [success_message, false] : [error_message, true] 
   end

   def check_object_counter_cache_values_match_actual_values(question)
        error_message = ""
        success_message = "All cached object values match actual values within database"
        # Checks that counter_cache is working as expected
	cached_prompts_size = question.prompts.size
	actual_prompts_size = question.prompts.count

	if cached_prompts_size != actual_prompts_size
		error_message += "Error! Question #{question.id} has an inconsistent # of prompts! cached#: #{cached_prompts_size}, actual#: #{actual_prompts_size}\n"
	end
	
	cached_votes_size = question.votes.size
	actual_votes_size = question.votes.count

	if cached_votes_size != actual_votes_size
		error_message += "Error! Question #{question.id} has an inconsistent # of votes! cached#: #{cached_votes_size}, actual#: #{actual_votes_size}\n"
	end
	
	cached_choices_size = question.choices.size
	actual_choices_size = question.choices.count

	if cached_choices_size != actual_choices_size
		error_message+= "Error! Question #{question.id} has an inconsistent # of choices! cached#: #{cached_choices_size}, actual#: #{actual_choices_size}\n"
	end

	if cached_prompts_size != question.choices.size **2 - question.choices.size 
		error_message += "Error! Question #{question.id} has an incorrect number of prompts! Expected #{question.choices.size **2 - question.choices.size}, Actual: #{cached_prompts_size}\n"
	end
        return error_message.blank? ? [success_message, false] : [error_message, true] 
   end
   
   def ensure_all_votes_and_skips_have_unique_appearance
     error_message = ""
     success_message = "All vote and skip objects have an associated appearance object"
     votes_without_appearances= Vote.count(:conditions => {:appearance_id => nil})
     if (votes_without_appearances > 0)
	     error_message += "Error! There are #{votes_without_appearances} votes without associated appearance objects."
     end

     skips_without_appearances= Skip.count(:conditions => {:appearance_id => nil})
     if (skips_without_appearances > 0)
	     error_message += "Error! There are #{skips_without_appearances} skips without associated appearance objects."
     end
     
     return error_message.blank? ? [success_message, false] : [error_message, true] 
   end

   def response_time_tests
     error_message = ""
     success_message = "All Vote objects have an client response time < calculated server roundtrip time\n" 

     recording_client_time_start_date = Vote.find(:all, :conditions => 'time_viewed IS NOT NULL', :order => 'created_at', :limit => 1).first.created_at

     Vote.find_each(:batch_size => 1000, :include => :appearance) do |v|

	     # Subtracting DateTime objects results in the difference in days
	     server_response_time = v.created_at.to_f - v.appearance.created_at.to_f
	     if server_response_time < 0
	        the_error_msg = "Error! Vote #{v.id} was created before the appearance associated with it: Appearance id: #{v.appearance.id}, Vote creation time: #{v.created_at.to_s}, Appearance creation time: #{v.appearance.created_at.to_s}\n"

		error_message += the_error_msg
		print "Error!" + the_error_msg
	     end

	     if v.time_viewed && v.time_viewed/1000 > server_response_time 
		     the_error_msg = "Error! Vote #{v.id} with Appearance #{v.appearance.id}, has a longer client response time than is possible. Vote creation time: #{v.created_at.to_s}, Appearance creation time: #{v.appearance.created_at.to_s}, Client side response time: #{v.time_viewed}\n"

		     error_message += the_error_msg
	             print the_error_msg

             elsif v.time_viewed.nil?
		     if v.created_at > recording_client_time_start_date && v.missing_response_time_exp != 'invalid'
	                the_error_msg = "Error! Vote #{v.id} with Appearance #{v.appearance.id}, does not have a client response, even though it should! Vote creation time: #{v.created_at.to_s}, Appearance creation time: #{v.appearance.created_at.to_s}, Client side response time: #{v.time_viewed}\n"
		        error_message += the_error_msg
	                print the_error_msg
		     end

	     end

       end
	
        return error_message.blank? ? [success_message, false] : [error_message, true] 
     end
end

