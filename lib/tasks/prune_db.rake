namespace :prune_db do

  task :all => [:invalidate_votes_with_bad_response_times]

  desc "Fixes a mis-match between a vote's prompt_id and its appearance's prompt_id. Sets the appearance prompt_id to match the vote's prompt_id"
  task :fix_promptid_mismatch => :environment do
    bad_records = Vote.connection.select_all "
      SELECT
        votes.prompt_id, appearances.id appearance_id,
        appearances.prompt_id appearance_prompt_id
      FROM votes LEFT JOIN appearances
        ON (votes.id = appearances.answerable_id
            AND appearances.answerable_type = 'Vote')
      WHERE votes.prompt_id <> appearances.prompt_id"
    bad_records.each do |record|
      Appearance.update_all("prompt_id = #{record["prompt_id"]}", "id = #{record["appearance_id"]} AND prompt_id = #{record["appearance_prompt_id"]}")
    end
  end

  desc "Invalidates votes with bad response times"
  task :invalidate_votes_with_bad_response_times => :environment do
    badvotes = [] 
    #might want to optimize later to not start from the beginning each time
    STDOUT.sync = true
    Vote.find_each(:batch_size => 10000, :include => :appearance) do |v|
      next if v.nil? || v.appearance.nil?
      server_response_time = v.created_at.to_f - v.appearance.created_at.to_f
      if v.time_viewed && v.time_viewed/1000 > server_response_time 
        badvotes << v
        print "."
      end
    end
    puts "\n"

    if badvotes.any?

      badvotes.each do |v|
        v.time_viewed = nil
        v.missing_response_time_exp = "invalid"
        v.save!
      end
    else
      puts "Could not find any bad votes. Yay."
    end
  end

  task :associate_skips_with_appearances => :environment do
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
    #Vote.find_each do |v|
    #    @appearance = Appearance.find(v.appearance_id)
    #	  @appearance.answerable = v
    #	  @appearance.save
    #	  if v.id % 1000 == 0
    #		  puts v.id
    #	  end
    #      end
    Skip.find_each do |s|
      if s.appearance_id
        @appearance = Appearance.find(s.appearance_id)

        if @appearance.answerable
          puts "Appearance #{@appearance.id} has more than one skip!"
        else
          @appearance.answerable = s
          @appearance.save
        end
      end
    end
  end

  task(:remove_double_counted_votes_with_same_appearance => :environment) do 

    votes_with_no_appearance = []
    Vote.find_each(:include => :appearance) do |v|
      puts v.id if v.id % 1000 == 0

      votes_with_no_appearance << v if v.appearance.nil?
    end

    skips_with_no_appearance = []
    Skip.find_each(:include => :appearance) do |s|
      puts s.id if s.id % 1000 == 0

      skips_with_no_appearance << s if s.appearance.nil?
    end


    puts "#{votes_with_no_appearance.size} Votes"
    puts "#{skips_with_no_appearance.size} Skips"

    votes_with_no_appearance.each do |v|
      v.valid_record = false
      v.validity_information = "No associated appearance object"
      v.save!
    end

    skips_with_no_appearance.each do |s|
      s.valid_record = false
      s.validity_information = "No associated appearance object"
      s.save!
    end

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

  desc "Searches questions for orphaned votes (votes with no appearance) and marks them as invalid"
  task :invalidate_orphaned_votes => :environment do
    question_ids = ENV["question_ids"].split(/[\s,]+/)
    question_ids.each do |question_id|
      question = Question.find(question_id)

      orphaned_votes = Vote.find(:all,
                                 :select => "votes.id",
                                 :joins  => "LEFT JOIN appearances ON (votes.id = appearances.answerable_id AND answerable_type <> 'Skip')",
                                 :conditions => ["answerable_id IS NULL AND votes.valid_record = 1 AND votes.question_id = ?", question.id])
      puts "Question ##{question.id} has #{orphaned_votes.count} orphaned votes"
      orphaned_votes.each do |orphaned_vote_id|
        orphaned_vote = Vote.find(orphaned_vote_id.id)

        # attempt to find sibling vote
        # sibling vote is one that is valid has the same voter and prompt,
        # is associated with an appearance, and created within 10 seconds
        sibling_vote = nil
        votes = Vote.find(:all, :conditions => {:voter_id => orphaned_vote.voter_id, :prompt_id => orphaned_vote.prompt_id})
        votes.each do |vote|
          next if vote.id == orphaned_vote.id
          next if vote.created_at > orphaned_vote.created_at + 5.seconds
          next if vote.created_at < orphaned_vote.created_at - 5.seconds
          next if vote.appearance == nil
          sibling_vote = vote
          break
        end
        info = "Appearance XXXX already answered"
        if sibling_vote
          info = "Appearance #{sibling_vote.appearance.id} already answered"
        end
        orphaned_vote.update_attributes!(:valid_record => false, :validity_information => info)
      end
    end
  end

  desc "Updates cached values for losses and wins for choices."
  task :update_cached_losses_wins => :environment do
    Question.all.each do |question|
      question.choices.each do |choice|
        choice.reload
        true_losses = question.votes.count(:conditions => {:loser_choice_id => choice.id})
        true_wins = choice.votes.count
        Choice.update_counters choice.id,
          :losses => (true_losses - choice.losses), 
          :wins   => (true_wins - choice.wins)
        choice.reload
        choice.score = choice.compute_score
        choice.save(false)
      end
    end
  end

  desc "Update cached values for prompts on left and right for choices."
  task :update_cached_prompts_on_left_right => :environment do
    question_ids = ENV["question_ids"].split(/[\s,]+/) if ENV["question_ids"]
    if !question_ids.blank?
      questions = Question.find(question_ids)
    else
      questions = Question.all
    end
    questions.each do |question|
      question.choices.each do |choice|
        choice.reload
        Choice.update_counters choice.id,
          :prompts_on_the_left_count => choice.prompts_on_the_left.count - choice.prompts_on_the_left_count,
          :prompts_on_the_right_count => choice.prompts_on_the_right.count - choice.prompts_on_the_right_count
      end
    end
  end

  desc "Recomputes scores for all choices."
  task :recompute_scores => :environment do
    Choice.find_each do |choice|
      choice.reload
      choice.score = choice.compute_score
      choice.save(false)
    end
  end

end
