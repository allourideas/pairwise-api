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

      end
      Skip.find_each do |s|
          @appearance = Appearance.find(s.appearance_id)
	  @appearance.answerable = s
	  @appearance.save
      end
  end

  #call this by doing rake prune_db:populate_seed_ideas['blahblah'], where blahblah is the filename
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
