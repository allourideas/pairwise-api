namespace :test_api do

   task :all => [:question_vote_consistency]

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

	wins_by_choice_id = question.votes.count(:group => :choice_id)
	losses_by_choice_id= question.votes.count(:conditions => "loser_choice_id IS NOT NULL", :group => :loser_choice_id)

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
			 "     2 x Total Wins = Total Votes " +
			 "     Total Votes (wins + losses) is Even" +
			 "     Total Votes (wins + losses) = 2 x the number of vote objects that belong to the question" +
		         "     Total generated prompts on left = Total generated prompts on right" + 
		         "     Each choice has appeared n times, where n falls within 6 stddevs of the mean number of appearances for a question"

	print success_msg

	CronMailer.deliver_info_message(CRON_EMAIL, "Test of API Vote Consistency passed", success_msg)
     else
     	CronMailer.deliver_info_message("#{CRON_EMAIL},#{ERRORS_EMAIL}", "Error! Failure of API Vote Consistency " , error_msg)
     end

   end
end

