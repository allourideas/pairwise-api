namespace :test_api do

  desc "Run all API tests"
  task :all => [:question_vote_consistency]

  desc "Ensure all appearance and votes have matching prompt_ids"
  task :verify_appearance_vote_prompt_ids => :environment do
    puts verify_appearance_vote_prompt_ids().inspect
  end

  def verify_appearance_vote_prompt_ids
    bad_records = Vote.connection.select_all "
      SELECT votes.id
      FROM votes LEFT JOIN appearances
        ON (votes.id = appearances.answerable_id
            AND appearances.answerable_type = 'Vote')
      WHERE votes.prompt_id <> appearances.prompt_id"
    success_message = "Appearance and vote prompt_ids match"
    error_message = bad_records.map do |record|
      "Vote ##{record["id"]} has a different prompt_id than its appearance."
    end
    error_message = error_message.join "\n"
    return error_message.blank? ? [success_message, false] : [error_message, true]
  end

  desc "Ensure that all choices have 0 <= score <= 100"
  task :verify_range_of_choices_scores => :environment do
    puts verify_range_of_choices_scores().inspect
  end

  def verify_range_of_choices_scores
    bad_choices_count = Choice.count(:conditions => 'score < 0 OR score > 100')
    success_message = "All choices have a score within 0-100"
    if bad_choices_count > 0
      error_message = "Some choices have a score less than 0 or greater than 100"
    end
    return error_message.blank? ? [success_message, false] : [error_message, true]
  end

  namespace :choice do
    desc "Ensure that cached prompt counts are valid for a choice"
    task :verify_cached_prompt_counts, [:choice_id] => :environment do |t, args|
      choice = Choice.find(args[:choice_id])
      puts verify_cached_prompt_counts(choice).inspect
    end

    def verify_cached_prompt_counts(choice)
      success_message = "Choice has accurate prompt cache count"
      if choice.prompts_on_the_left.count != choice.prompts_on_the_left_count || choice.prompts_on_the_right.count != choice.prompts_on_the_right_count
        error_message = "Choice #{choice.id} in Question ##{choice.question_id} has inaccurate prompt count cache"
      end
      return error_message.blank? ? [success_message, false] : [error_message, true]
    end

    desc "Ensure that an idea: appearances on left + appearances on right >= (wins + losses + skips)"
    task :verify_choice_appearances_and_votes, [:choice_id] => :environment do |t, args|
      choice = Choice.find(args[:choice_id])
      puts verify_choice_appearances_and_votes(choice).inspect
    end

    def verify_choice_appearances_and_votes(choice)
      success_message = "Choice has more appearances than votes and skips"
      all_appearances  = choice.appearances_on_the_left.count + choice.appearances_on_the_right.count
      skips = choice.skips_on_the_left.count + choice.skips_on_the_right.count

      if all_appearances < choice.wins + choice.losses + skips
        error_message = "Choice #{choice.id} in Question ##{choice.question_id} has fewer appearances than wins + losses + skips"
      end
      return error_message.blank? ? [success_message, false] : [error_message, true]
    end
  end

  desc "Description here"
  task(:question_vote_consistency => :environment) do
    questions = Question.find(:all)
    errors = []
    successes = []

    questions.each do |question|

      message, error_occurred = check_basic_balanced_stats(question)
      # hack for now, get around to doing this with block/yield to
      # get rid of duplication
      if error_occurred
        errors << message
      else
        successes << message
      end

      message, error_occurred = answered_appearances_equals_votes_and_skips(question)
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

    message, error_occurred = response_time_tests  

    if error_occurred
      errors << message
    else
      successes << message
    end
    message, error_occurred = verify_range_of_choices_scores
    if error_occurred
      errors << message
    else
      successes << message
    end
    message, error_occurred = verify_appearance_vote_prompt_ids
    if error_occurred
      errors << message
    else
      successes << message
    end

    email_text = "Conducted the following tests on API data and found the following results\n" + "For each of the #{questions.length} questions in the database: \n"
    errors.each do |e|
      email_text += "     Test FAILED:\n" + e + "\n"
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
      CronMailer.deliver_info_message(CRON_EMAIL.to_a + ERRORS_EMAIL.to_a, "Error! Failure of API Vote Consistency " , email_text)
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
    # votes before 2010-02-17 have null loser_choice_id therefore we
    # want to ignore some tests for any question with votes before 2010-02-17
    question_has_votes_before_2010_02_17 = question.votes.count(:conditions => ["created_at < ?", '2010-02-17']) > 0

    # reload question to make sure we have most recent data
    question.reload
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
        error_message += "Error! The cached_score is not equal to the calculated score for choice #{choice.id}\n"

        print "This score is wrong! #{choice.id} , Question ID: #{question.id}, #{cached_score}, #{generated_score}, updated: #{choice.updated_at}\n"


      end

      if cached_score == 0.0 || cached_score == 100.0 || cached_score.nil?
        error_message += "Error! The cached_score for choice #{choice.id} is exactly 0 or 100, the value: #{cached_score}"
        print "Either 0 or 100 This score is wrong! #{choice.id} , Question ID: #{question.id}, #{cached_score}, #{generated_score}, updated: #{choice.updated_at}\n"
      end

      unless question_has_votes_before_2010_02_17
        message, error_occurred = verify_choice_appearances_and_votes(choice)
        if error_occurred
          error_message += message + "\n"
        end
      end

      message, error_occurred = verify_cached_prompt_counts(choice)
      if error_occurred
        error_message += message + "\n"
      end


      if cached_score >= 50
        total_scores_gte_fifty +=1
      end
      if cached_score <= 50
        total_scores_lte_fifty +=1
      end

      if (choice.wins != choice.votes.count)
        error_message += "Error!: Cached choice wins != actual choice wins for choice #{choice.id}\n"
        error_bool= true
      end

      # votes before 2010-02-17 have null loser_choice_id
      # therefore we want to ignore this test for any question with votes
      # prior to 2010-02-17
      unless question_has_votes_before_2010_02_17
        if (choice.losses != question.votes.count(:conditions => {:loser_choice_id => choice.id}))
          error_message += "Error!: Cached choice losses != actual choice losses for choice #{choice.id}\n"
          error_bool= true
        end
      end

    end


    unless question_has_votes_before_2010_02_17
      if (2*total_wins != total_votes)
        error_message += "Error 1: 2 x Total Wins != Total votes\n"
        error_bool= true
      end

      if(total_votes % 2 != 0)
        error_message += "Error 2: Total votes is not Even!\n"
        error_bool= true
      end

      if(total_votes != 2* question.votes_count)
        error_message += "Error 3: Total votes != 2 x # vote objects\n"
        error_bool = true
      end
    end

    if(total_generated_prompts_on_right != total_generated_prompts_on_right)
      error_message += "Error 4: Total generated prompts on left != Total generated prompts on right\n"
      error_bool = true
    end

    unless question_has_votes_before_2010_02_17
      if(total_scores_lte_fifty == question.choices.size || total_scores_gte_fifty == question.choices.size) && (total_scores_lte_fifty != total_scores_gte_fifty)
        error_message += "Error: The scores of all choices are either all above 50, or all below 50. This is probably wrong\n"
        error_bool = true
        puts "Error score fifty: #{question.id}"
      end
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

    wins_by_choice_id = question.votes.active.count(:group => :choice_id, :conditions => ["creator_id = ?", question.creator_id])
    losses_by_choice_id= question.votes.active_loser.count(:group => :loser_choice_id, :conditions => ["creator_id = ?", question.creator_id])

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

      # this choice appears to have been deactivated then reactivated after
      # a period of voting
      ignore_choices = [133189]
      appearances_by_choice_id.each do |choice_id, n_i| 
        if ((n_i < (mean - 6*stddev)) || (n_i > mean + 6 *stddev)) && !ignore_choices.include?(choice_id) && Choice.find(choice_id).active?
          error_message += "Choice #{choice_id} in Question ##{question.id} has an irregular number of appearances: #{n_i}, as compared to the mean: #{mean} and stddev #{stddev} for this question\n"
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

    yesterday_appearances = question.appearances.count(:conditions => ['date(created_at) = ?', Date.yesterday])

    if misses + hits != yesterday_appearances
      error_message += "Error! Question #{question.id} isn't tracking prompt cache hits and misses accurately! Expected #{yesterday_appearances}, Actual: #{misses+hits}, Hits: #{hits}, Misses: #{misses}\n"
    end

    if yesterday_appearances > 5 # this test isn't worthwhile for small numbers of appearances
      miss_rate = misses.to_f / yesterday_appearances.to_f
      if miss_rate > 0.1
        error_message += "Warning! Question #{question.id} has less than 90% of appearances taken from a pre-generated cache! Expected <#{0.1}, Actual: #{miss_rate}, total appearances yesterday: #{yesterday_appearances}\n"
      end
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

    #if cached_prompts_size != question.choices.size **2 - question.choices.size 
    # error_message += "Error! Question #{question.id} has an incorrect number of prompts! Expected #{question.choices.size **2 - question.choices.size}, Actual: #{cached_prompts_size}\n"
    #end
    return error_message.blank? ? [success_message, false] : [error_message, true] 
  end

  namespace :question do

    desc "Ensure that a question has: answered_appearances == votes + skips"
    task :answered_appearances_equals_votes_and_skips, [:question_id] => :environment do |t, args|
      a = cleanup_args(args)
      questions = Question.find(a[:question_id])
      questions.each do |question|
        puts answered_appearances_equals_votes_and_skips(question).inspect
      end
    end

  end

  def answered_appearances_equals_votes_and_skips(question)
    error_message = ""
    success_message = "All vote and skip objects have an associated appearance object"
    skip_appearances_count = Appearance.count(
      :conditions => ["skips.valid_record = 1 and appearances.question_id = ? AND answerable_id IS NOT NULL AND answerable_type = 'Skip'", question.id],
      :joins => "LEFT JOIN skips ON (skips.id = appearances.answerable_id)")
    vote_appearances_count = Appearance.count(
      :conditions => ["votes.valid_record = 1 and appearances.question_id = ? AND answerable_id IS NOT NULL and answerable_type = 'Vote'", question.id],
      :joins => "LEFT JOIN votes ON (votes.id = appearances.answerable_id)")
    total_answered_appearances = skip_appearances_count + vote_appearances_count
    total_votes = question.votes.count
    total_skips = question.skips.count
    if (total_answered_appearances != total_votes + total_skips)
      error_message += "Question #{question.id}: answered_appearances = #{total_answered_appearances}, votes = #{total_votes}, skips = #{total_skips}"
    end


    return error_message.blank? ? [success_message, false] : [error_message, true] 
  end

  def response_time_tests
    error_message = ""
    success_message = "All Vote objects have an client response time < calculated server roundtrip time\n" 

    recording_client_time_start_date = Vote.find(:all, :conditions => 'time_viewed IS NOT NULL', :order => 'created_at', :limit => 1).first.created_at

    Vote.find_each(:batch_size => 1000, :include => :appearance) do |v|

      next if v.nil? || v.appearance.nil?
      # Subtracting DateTime objects results in the difference in days
      server_response_time = v.created_at.to_f - v.appearance.created_at.to_f
      if server_response_time < 0
        the_error_msg = "Error! Vote #{v.id} was created before the appearance associated with it: Appearance id: #{v.appearance.id}, Vote creation time: #{v.created_at.to_s}, Appearance creation time: #{v.appearance.created_at.to_s}\n"

        error_message += the_error_msg
        print "Error!" + the_error_msg
      end

      if v.time_viewed && v.time_viewed/1000 > server_response_time 
        the_error_msg = "Warning! Vote #{v.id} with Appearance #{v.appearance.id}, has a longer client response time than is possible. Server roundtrip time is: #{v.created_at.to_f - v.appearance.created_at.to_f} seconds, but client side response time is: #{v.time_viewed.to_f / 1000.0} seconds\n"

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

def cleanup_args(args)
  args.with_defaults(:question_id => :all, :choice_id => :all)
  a = args.to_hash
  if a[:question_id] != :all
    a[:question_id] = a[:question_id].split(".")
  end
  if a[:choice_id] != :all
    a[:choice_id] = a[:choice_id].split(".")
  end
  a
end
