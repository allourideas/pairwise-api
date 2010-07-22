namespace :prune_db do
  
  task :all => [:invalidate_votes_with_bad_response_times]

  task(:invalidate_votes_with_bad_response_times => :environment) do
     badvotes = [] 
     #might want to optimize later to not start from the beginning each time
     Vote.find_each(:batch_size => 1000, :include => :appearance) do |v|
         server_response_time = v.created_at.to_f - v.appearance.created_at.to_f
	 if v.time_viewed && v.time_viewed/1000 > server_response_time 
            badvotes << v
	    puts "."
	 end
     end
     puts "\n"

     if badvotes.any?
       puts "You are about to change #{badvotes.size} votes. Are you sure you want to proceed? (y/N)"
       choice = $stdin.gets

       unless choice.chomp.downcase == "y"
	       return
       end

       badvotes.each do |v|
          v.time_viewed = nil
          v.missing_response_time_exp = "invalid"
          v.save!
       end
     else
       puts "Could not find any bad votes. Yay."
     end
  end
  
  task(:associate_skips_with_appearances => :environment) do
     skips_to_fix = Skip.find(:all, :conditions => {:appearance_id => nil})
     skips_to_fix.each do |skip|
	puts "Skip #{skip.id} : "
        possible_appearances = skip.skipper.appearances.find(:all, :conditions => {:prompt_id => skip.prompt_id})
	if possible_appearances.nil? || possible_appearances.empty?
	   puts " I couldn't find any matches!"
	   skip.delete
	   next
	end
	if possible_appearances.size > 1
	    puts " More than one possible appearance"
	    possible_appearances.delete_if{|a| a.answered?}
	    if possible_appearances.size > 1 || possible_appearances.size == 0
		puts"   And I couldn't narrow it down.... moving on"
		skip.delete
	        next
	    end
	end
	possible_appearance = possible_appearances.first
        if possible_appearance.answered?
	   puts " This appearance has been answered already! Moving on" 
	   skip.delete
	else
	   puts " MATCH"
	   skip.appearance_id = possible_appearance.id
	   skip.save!
	end
     end
  end
  
  task(:move_vote_and_skip_ids_to_appearance => :environment) do
      Vote.find_each do |v|
          @appearance = Appearance.find(v.appearance_id)
	  @appearance.answerable = v
	  @appearance.save
	  if v.id % 1000 == 0
		  puts v.id
	  end
      end
      Skip.find_each do |s|
	  if s.appearance_id
             @appearance = Appearance.find(s.appearance_id)
	     @appearance.answerable = s
	     @appearance.save
	  end
      end
  end

  task(:remove_double_counted_votes_with_same_appearance => :environment) do 
     problem_appearances = Vote.count(:group => :appearance_id, :having => "count(*) > 1")
     count = 0
     choice_count = 0
     voter_count = 0
     problem_appearances.each do |id, num|
         votes = Vote.find(:all, :conditions => {:appearance_id => id}, :order => 'id ASC')
	 choices = votes.map{|v| v.choice_id}
	 voters = votes.map{|v| v.voter_id}
	 questions = votes.map{|v| v.question_id}

	 if choices.uniq.size > 1 || voters.uniq.size > 1 
	    count+=1
	    puts "Appearance #{id}, on Question #{questions.uniq.first} has more than one inconsistent vote"
	    if choices.uniq.size > 1
		    puts "  There are #{choices.uniq.size} different choices!"
		    choice_count +=1
	    end
	    if voters.uniq.size > 1
		    puts "  There are #{voters.uniq.size} different voters!"
		    voter_count +=1
	    end

	    if votes.size == 2
		    puts "  There was #{votes.second.created_at.to_f - votes.first.created_at.to_f} seconds between votes"
	    end
	 end

	 votes = votes - [votes.first] # keep the first valid vote
	 votes.each do |v|
		 v.valid_record = false
		 v.validity_information = "Double counted vote"
		 v.save
	 end
     end

     # one vote and one skip:
     #
     double_counted_appearances = ActiveRecord::Base.connection.select_all("select votes.appearance_id from skips inner join votes using (appearance_id) where votes.valid_record=1 AND skips.valid_record=1;")

     puts double_counted_appearances.inspect

     double_counted_appearances.each do |result|
	     v = result["appearance_id"]
	     vote = Vote.find(:first, :conditions => {:appearance_id => v})
	     skip = Skip.find(:first, :conditions => {:appearance_id => v})

	     if vote.created_at < skip.created_at
		     object = skip
		     good_object = vote
	     else
		     object = vote
		     good_object = skip
	     end

	     object.valid_record = false
	     object.validity_information = "Double counted vote"
	     object.save

	     @appearance = Appearance.find(good_object.appearance_id)
	     @appearance.answerable = good_object
	     @appearance.save
     end

     puts "Total inconsistent appearances: #{count}"
     puts "   #{choice_count} have inconsistent choices voted on"
     puts "   #{voter_count} have inconsistent voters"
  end

  #call this by doing rake prune_db:populate_seed_ideas['blahblah',questionnum], where blahblah is the filename
  task(:populate_seed_ideas, :args1, :args2, :needs => :environment) do | task, arguments|
      filename = arguments[:args1]
      question_num = arguments[:args2]

      puts filename
      puts question_num

      q = Question.find(question_num)
      creator_id = q.creator_id

      File.open(filename, "r") do |infile|
         while( data= infile.gets)
		 c = Choice.new(:creator_id => creator_id,
				:question_id => q.id,
				:active => true,
				:data => data.chomp)

		 c.save
	 end
      end

  end

end
