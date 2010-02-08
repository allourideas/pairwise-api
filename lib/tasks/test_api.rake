namespace :test_api do

   desc "Description here"
   task(:question_vote_consistency => :environment) do
      questions = Question.find(:all)

      error_msg = ""
      questions.each do |question|

	total_wins =0
	total_votes =0
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
		 error_msg += "Error:"
	end

	if(total_votes % 2 != 0)
		error_msg += "ERROR"
	end

	error_msg += "Question #{question.id}: 2*wins = #{2*total_wins}, total votes = #{total_votes}\n"
     end
     
     CronMailer.deliver_error_message("This is a test", "")

   end
end

