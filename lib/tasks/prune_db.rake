namespace :prune_db do

  desc "Finds ambiguous times due to daylight savings time"
  task :find_ambiguous_times => :environment do
    datetime_fields = {
      :appearances  => ['created_at', 'updated_at'],
      :choices      => ['created_at', 'updated_at'],
      :clicks       => ['created_at', 'updated_at'],
      :densities    => ['created_at', 'updated_at'],
      :flags        => ['created_at', 'updated_at'],
      :prompts      => ['created_at', 'updated_at'],
      :skips        => ['created_at', 'updated_at'],
      :votes        => ['created_at', 'updated_at'],
      :visitors     => ['created_at', 'updated_at'],
      :users        => ['created_at', 'updated_at'],
      :questions    => ['created_at', 'updated_at'],
      :question_versions => ['created_at', 'updated_at'],
      :delayed_jobs => ['created_at', 'updated_at', 'run_at', 'locked_at', 'failed_at'],
    }
    datetime_fields.each do |table, columns|
      where = columns.map{|c| "((#{c} > '2010-11-07 00:59:59' AND #{c} < '2010-11-07 02:00:00') OR (#{c} > '2011-11-06 00:59:59' AND #{c} < '2011-11-06 02:00:00'))"}.join(" OR ")
      rows = ActiveRecord::Base.connection.select_all(
        "SELECT id, #{columns.join(", ")} FROM #{table} WHERE #{where}"
      )
      puts rows.inspect if rows.length > 0
    end
  end

  desc "Converts all dates from PT to UTC"
  task :convert_dates_to_utc => :environment do
    time_spans = [
      { :gt => "2009-11-01 02:00:00", :lt => "2010-03-14 02:00:00", :h => 8},
      { :gt => "2010-03-14 02:00:00", :lt => "2010-11-07 01:00:00", :h => 7},
      { :gt => "2010-11-07 01:00:00", :lt => "2010-11-07 02:00:00", :h => nil},
      { :gt => "2010-11-07 02:00:00", :lt => "2011-03-13 02:00:00", :h => 8},
      { :gt => "2011-03-13 02:00:00", :lt => "2011-11-06 01:00:00", :h => 7},
      { :gt => "2011-11-06 01:00:00", :lt => "2011-11-06 02:00:00", :h => nil},
      { :gt => "2011-11-06 02:00:00", :lt => "2012-03-11 02:00:00", :h => 8},
      { :gt => "2012-03-11 02:00:00", :lt => "2012-11-04 01:00:00", :h => 7}
    ]
    # UTC because Rails will be thinking DB is in UTC when we run this
    time_spans.map! do |t|
      { :gt => Time.parse("#{t[:gt]} UTC"),
        :lt => Time.parse("#{t[:lt]} UTC"),
        :h  => t[:h] }
    end
    datetime_fields = {
      :appearances  => ['created_at', 'updated_at'],
      :choices      => ['created_at', 'updated_at'],
      :clicks       => ['created_at', 'updated_at'],
      :densities    => ['created_at', 'updated_at'],
      :flags        => ['created_at', 'updated_at'],
      :prompts      => ['created_at', 'updated_at'],
      :skips        => ['created_at', 'updated_at'],
      :votes        => ['created_at', 'updated_at'],
      :visitors     => ['created_at', 'updated_at'],
      :users        => ['created_at', 'updated_at'],
      :questions    => ['created_at', 'updated_at'],
      :question_versions => ['created_at', 'updated_at'],
      :delayed_jobs => ['created_at', 'updated_at', 'run_at', 'locked_at', 'failed_at'],
    }

    STDOUT.sync = true
    logger = Rails.logger
    datetime_fields.each do |table, columns|
      print "#{table}"
      batch_size = 10000
      i = 0
      while true do
        rows = ActiveRecord::Base.connection.select_all(
          "SELECT id, #{columns.join(", ")} FROM #{table} ORDER BY id LIMIT #{i*batch_size}, #{batch_size}"
        )
        print "."

        rows.each do |row|
          updated_values = {}
          # delete any value where the value is blank
          row.delete_if {|key, value| value.blank? }
          row.each do |column, value|
            next unless value.class == Time
            time_spans.each do |span|
              if value < span[:lt] && value > span[:gt]
                # if blank then ambiguous and we don't know how to translate
                if span[:h].blank?
                  logger.info "AMBIGUOUS: #{table} #{row["id"]} #{column}: #{value}"
                  updated_values[column] = nil
                else
                  updated_values[column] = value + span[:h].hours
                end
                break
              end
            end
          end
          # Check if some columns did not match any spans
          key_diff = row.keys - updated_values.keys - ["id"]
          if key_diff.length > 0
            logger.info "MISSING SPAN: #{table} #{row["id"]} #{key_diff.inspect} #{row.inspect}"
          end
          # remove ambiguous columns (we set them to nil above)
          updated_values.delete_if {|key, value| value.blank? }
          if updated_values.length > 0
            logger.info "UPDATE: #{table} #{row.inspect} #{updated_values.inspect}"
          end
        end

        i+= 1
        break if rows.length < 1000
      end
      print "\n"
    end
  end

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

  desc "Don't run unless you know what you are doing"
  task(:generate_lots_of_votes => :environment) do
    if Rails.env.production?
      print "You probably don't want to run this in production as it will falsify a bunch of random votes"
    end


    current_user = User.first
    1000.times do |n|
      puts "#{n} votes completed" if n % 100 == 0
      question = Question.find(214) # test question change as needed
      @prompt = question.catchup_choose_prompt(1).first
      @appearance = current_user.record_appearance(current_user.default_visitor, @prompt)

      direction = (rand(2) == 0) ? "left" : "right"
      current_user.record_vote(:prompt => @prompt, :direction => direction, :appearance_lookup => @appearance.lookup)
    end

  end

  desc "Dump votes of a question by left vs right id"
  task(:make_csv => :environment) do

    q = Question.find(214)


    the_prompts = q.prompts_hash_by_choice_ids

    #hash_of_choice_ids_from_left_to_right_to_votes
    the_hash = {}
    q.choices.each do |l|
      q.choices.each do |r|
        next if l.id == r.id

        if not the_hash.has_key?(l.id)
          the_hash[l.id] = {}
          the_hash[l.id][l.id] = 0
        end

        p = the_prompts["#{l.id}, #{r.id}"]
        if p.nil?
          the_hash[l.id][r.id] = 0
        else
          the_hash[l.id][r.id] = p.appearances.size
        end
      end
    end

    the_hash.sort.each do |xval, row|
      rowarray = []
      row.sort.each do |yval, cell|
        rowarray << cell
      end
      puts rowarray.join(", ")
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
  task(:populate_seed_ideas, [:args1, :args2,] => [:environment]) do | task, arguments|
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
