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

end
