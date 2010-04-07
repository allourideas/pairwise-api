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
	   end_date = Appearance.first.created_at.to_date

	   start_date.upto(end_date-1) do |the_date|
		   questions = Question.find(:all)

		   print the_date.to_s
		   questions.each do |q|
			   relevant_votes = q.votes.find(:all, :conditions => ['loser_choice_id IS NOT NULL AND created_at < ?', the_date])
			   relevant_choices = q.choices.find(:all, :conditions => ['created_at < ?', the_date])

			   seed_choices = 0

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

			   relevant_votes.each do |v|

				   p = v.prompt
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

   task(:generate_historical_density_data)

   desc "Should only need to be run once"
   task(:generate_all_possible_prompts => :environment) do
      inserts = []
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
        timestring = Time.now.to_s(:db) #isn't rails awesome?
	promptscount=0
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
	           print "."
	           inserts.push("(NULL, #{q.id}, NULL, #{l.id}, '#{timestring}', '#{timestring}', NULL, 0, #{r.id}, NULL, NULL)")
		   promptscount+=1
		end

	     end

	   end
         end

	print "Added #{promptscount} to #{q.id}\n"

       Question.update_counters(q.id, :prompts_count => promptscount)

       end

    sql = "INSERT INTO `prompts` (`algorithm_id`, `question_id`, `voter_id`, `left_choice_id`, `created_at`, `updated_at`, `tracking`, `votes_count`, `right_choice_id`, `active`, `randomkey`) VALUES #{inserts.join(', ')}"

    unless inserts.empty?
       ActiveRecord::Base.connection.execute(sql)
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
	   Question.find(:all).each do |q|
		   q.save_densities!
	   end
   end
      
   desc "Description here"
   task(:question_vote_consistency => :environment) do
      questions = Question.find(:all)

      error_msg = ""

      questions.each do |question|

	total_wins =0
	total_votes =0
	total_generated_prompts_on_left = 0
	total_generated_prompts_on_right = 0
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
        end
	
	if (2*total_wins != total_votes)
		 error_msg += "Error 1: 2 x Total Wins != Total votes"
		 error_bool= true
	end

	if(total_votes % 2 != 0)
		error_msg += "Error 2: Total votes is not Even!"
		error_bool= true
	end

	if(total_votes != 2* question.votes_count)
		error_msg += "Error 3: Total votes != 2 x # vote objects"
		error_bool = true
	end

	if(total_generated_prompts_on_right != total_generated_prompts_on_right)
		error_msg += "Error 4: Total generated prompts on left != Total generated prompts on right"
		error_bool = true
	end

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
			error_msg += "Choice #{choice_id} in Question ##{question.id} has an irregular number of appearances: #{n_i}, as compared to the mean: #{mean} and stddev #{stddev} for this question"
			error_bool = true
		end
	   end
	end
			


	if error_bool
	   error_msg += "Question #{question.id}: 2*wins = #{2*total_wins}, total votes = #{total_votes}, vote_count = #{question.votes_count}\n"
	end
	error_bool = false
     end
     
     if error_msg.blank?
        
	success_msg = "Conducted the following tests on API data and found no inconsistencies.\n" +
			 "For each of the #{questions.length} questions in the database: \n" +
			 "     2 x Total Wins = Total Votes\n" +
			 "     Total Votes (wins + losses) is Even\n" +
			 "     Total Votes (wins + losses) = 2 x the number of vote objects that belong to the question\n" +
		         "     Total generated prompts on left = Total generated prompts on right\n" + 
		         "     Each choice has appeared n times, where n falls within 6 stddevs of the mean number of appearances for a question\n" +
			 "             Note: this applies only to seed choices (not user submitted) and choices currently marked active\n"

	print success_msg

	CronMailer.deliver_info_message(CRON_EMAIL, "Test of API Vote Consistency passed", success_msg)
     else
     	CronMailer.deliver_info_message("#{CRON_EMAIL},#{ERRORS_EMAIL}", "Error! Failure of API Vote Consistency " , error_msg)
     end

   end
end

