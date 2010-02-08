namespace :test_api do

   task :all => [:question_vote_consistency]

   desc "Description here"
   task(:question_vote_consistency => :environment) do
      questions = Question.find(:all)

      error_msg = ""
      questions.each do |question|

	total_wins =0
	total_votes =0
	error_bool = false
	question.choices.each do |choice|
			
	    if choice.wins
	      total_wins += choice.wins
	      total_votes += choice.wins
	    end

	    if choice.losses
              total_votes += choice.losses
	    end
        end

	
	if (2*total_wins != total_votes)
		 error_msg += "Error 1:"
		 error_bool= true
	end

	if(total_votes % 2 != 0)
		error_msg += "Error 2:"
		error_bool= true
	end

	if(total_votes != question.votes_count)
		error_msg += "Error 3:"
		error_bool = true
	end

	if error_bool
	   error_msg += "Question #{question.id}: 2*wins = #{2*total_wins}, total votes = #{total_votes}, vote_count = #{question.votes_count}\n"
	end

	error_bool = false

     end
     
     if error_msg
     	CronMailer.deliver_error_message("Data in api check error!", error_msg)
     end

   end
end

