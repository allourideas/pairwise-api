namespace :test_api do

  desc "Run all API tests"
  task :all => [:question_ids_with_votes_before_2010_02_17, :question_vote_consistency]

  namespace :choice do
    @choice_tasks = {
      :verify_cached_prompt_counts => "Ensure that cached prompt counts are valid for a choice",
      :verify_choice_appearances_and_votes => "Ensure that an idea: appearances on left + appearances on right >= (wins + losses + skips)",
      :verify_valid_cached_score => "Verify that cached score is valid",
      :verify_cached_score_equals_computed_score => "Verify accurate cached score",
      :verify_wins_equals_vote_wins => "Verify wins equals vote wins",
      :verify_losses_equals_losing_votes => "Verify losses equals losing votes count"
    }

    # dynamically create tasks for each choice task
    @choice_tasks.each do |taskname, description|
      desc description
      task taskname, [:choice_id] => [:environment, :question_ids_with_votes_before_2010_02_17] do |t, args|
        a = cleanup_args(args)
        choices = Choice.find(a[:choice_id])
        choices.each do |choice|
          # call task
          puts send(taskname, choice).inspect
        end
      end
    end

    def verify_losses_equals_losing_votes(choice)
      error_message   = ""
      success_message = "Choice losses equals losing votes"
      # votes before 2010-02-17 have null loser_choice_id
      # therefore we want to ignore this test for any question with votes
      # prior to 2010-02-17
      return [success_message, false] if @question_ids_with_votes_before_2010_02_17.include?(choice.question_id)
      losing_votes_count = choice.losing_votes.count
      if (choice.losses != losing_votes_count)
        error_message = "Error!: Cached choice losses != actual choice losses for choice #{choice.id}, #{choice.losses} != #{losing_votes_count}\n"
      end
      return error_message.blank? ? [success_message, false] : [error_message, true]
    end

    def verify_wins_equals_vote_wins(choice)
      error_message   = ""
      success_message = "Choice wins equals vote wins"
      choice_votes_count = choice.votes.count
      if (choice.wins != choice_votes_count)
        error_message = "Error!: Cached choice wins != actual choice wins for choice #{choice.id}, #{choice.wins} != #{choice_votes_count}\n"
      end
      return error_message.blank? ? [success_message, false] : [error_message, true]
    end

    def verify_cached_score_equals_computed_score(choice)
      error_message   = ""
      success_message = "Choice has accurate cached score"
      cached_score = choice.score.to_f
      generated_score = choice.compute_score.to_f

      delta = 0.001

      if (cached_score - generated_score).abs >= delta
        error_message = "Error! The cached_score is not equal to the calculated score for choice #{choice.id} for question #{choice.question_id}, cached: #{cached_score}, computed: #{generated_score}\n"

      end
      return error_message.blank? ? [success_message, false] : [error_message, true]
    end

    def verify_valid_cached_score(choice)
      error_message   = ""
      success_message = "Choice has valid cached score"
      cached_score = choice.score.to_f
      if cached_score == 0.0 || cached_score == 100.0 || cached_score.nil?
        error_message = "Error! The cached_score for choice #{choice.id} is exactly 0 or 100, the value: #{cached_score}"
      end
      return error_message.blank? ? [success_message, false] : [error_message, true]
    end

    def verify_cached_prompt_counts(choice)
      error_message   = ""
      success_message = "Choice has accurate prompt cache count"
      if choice.prompts_on_the_left.count != choice.prompts_on_the_left_count || choice.prompts_on_the_right.count != choice.prompts_on_the_right_count
        error_message = "Choice #{choice.id} in Question ##{choice.question_id} has inaccurate prompt count cache"
      end
      return error_message.blank? ? [success_message, false] : [error_message, true]
    end

    def verify_choice_appearances_and_votes(choice)
      error_message   = ""
      success_message = "Choice has more appearances than votes and skips"
      return [success_message, false] if @question_ids_with_votes_before_2010_02_17.include?(choice.question_id)
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
    first_run_errors = []
    errors = []
    successes = []

    Question.find_each(:batch_size => 3) do |question|

      debug("Starting tasks for question #{question.id}")
      @question_tasks.each do |taskname, description|
        debug("Starting task #{taskname} for question #{question.id}")
        message, error_occurred = send(taskname, question)
        debug("Completed task #{taskname} for question #{question.id}")
        if error_occurred
          first_run_errors << [taskname, question]
        else
          successes << message
        end
      end

      debug("Starting choices tasks for question #{question.id}")
      question.choices.each do |choice|
        @choice_tasks.each do |taskname, description|
          message, error_occurred = send(taskname, choice)
          if error_occurred
            first_run_errors << [taskname, choice]
          else
            successes << message
          end
        end
      end
      debug("Completed choices tasks for question #{question.id}")

    end

    # retry the failed tasks in case they failed due to
    # votes happening while the test was running.
    debug("Re-running tasks that previously failed")
    first_run_errors.each do |err|
      message, error_occurred = send(err[0], err[1].reload)
      if error_occurred
        errors << message
      else
        successes << message
      end
    end

    @global_tasks.each do |taskname, description|
      debug("Starting global task #{taskname}")
      message, error_occurred = send(taskname)
      debug("Completed global task #{taskname}")
      if error_occurred
        errors << message
      else
        successes << message
      end
    end

    email_text = "Conducted the following tests on API data and found the following results\n" + "For each of the #{Question.all.count} questions in the database: \n"
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

  namespace :question do
    # use this to dynamically create rake task for each question test
    @question_tasks = {
      :answered_appearances_equals_votes_and_skips => "Ensure that a question has: answered_appearances == votes + skips",
      :check_each_choice_appears_within_n_stddevs => "Ensure each choice appears within 6 standard deviations",
      :check_each_choice_equally_likely_to_appear_left_or_right => "Ensure each choice is equally likely to appear on left or right",
      :check_prompt_cache_hit_rate => "Check prompt cache hit rate",
      :check_prompt_counter_cache => "Verify that prompt counter cache is accurate",
      :check_vote_counter_cache => "Verify that vote counter cache is accurate",
      :check_choice_counter_cache => "Verify that choice counter cache is accurate",
      :wins_and_losses_equals_two_times_wins => "Verifies that wins and losses are equal to 2 times the total number of wins",
      :wins_and_losses_is_even => "Verify that sum of wins and losses is even",
      :wins_and_losses_equals_two_times_vote_count => "Verify that sum of wins and losses equals two times the vote count",
      :check_scores_over_above_fifty => "Check that there are some scores above fifty and some below",
      :generated_prompts_on_each_side_are_equal => "Verify that count of generated prompts on each side is equal"
    }

    # dynamically create tasks for each question task
    @question_tasks.each do |taskname, description|
      desc description
      task taskname, [:question_id] => [:environment, :question_ids_with_votes_before_2010_02_17] do |t, args|
        a = cleanup_args(args)
        questions = Question.find(a[:question_id])
        questions.each do |question|
          # call task
          puts send(taskname, question).inspect
        end
      end
    end

    def generated_prompts_on_each_side_are_equal(question)
      error_message   = ""
      success_message = "Number of generated prompts on left are equal to number generated on right"
      generated_on_left = Choice.connection.select_one("
        SELECT COUNT(*) AS total FROM prompts
         WHERE question_id = #{question.id} AND left_choice_id IN (SELECT id from choices where question_id = #{question.id})")
      generated_on_right = Choice.connection.select_one("
        SELECT COUNT(*) AS total FROM prompts
         WHERE question_id = #{question.id} AND right_choice_id IN (SELECT id from choices where question_id = #{question.id})")
      if (generated_on_left["total"] != generated_on_right["total"])
        error_message = "Question #{question.id}: Total generated prompts on left (#{generated_on_left["total"]}) != Total generated prompts on right (#{generated_on_right["total"]})"
      end
      return error_message.blank? ? [success_message, false] : [error_message, true] 
    end

    def check_scores_over_above_fifty(question)
      error_message   = ""
      success_message = "Scores are distributed above and below 50"
      return [success_message, false] if @question_ids_with_votes_before_2010_02_17.include?(question.id)
      totals_lte_fifty = Choice.connection.select_one("
        SELECT COUNT(*) AS total FROM choices
         WHERE question_id = #{question.id} AND score <= 50")
      totals_gte_fifty = Choice.connection.select_one("
        SELECT COUNT(*) AS total FROM choices
         WHERE question_id = #{question.id} AND score >= 50")
      total_scores_lte_fifty = totals_lte_fifty["total"]
      total_scores_gte_fifty = totals_gte_fifty["total"]
      question_choices_count = question.choices.count
      if (total_scores_lte_fifty == question_choices_count || total_scores_gte_fifty == question_choices_count) && (total_scores_lte_fifty != total_scores_gte_fifty)
        error_message = "Question #{question.id}: The scores of all choices are either all above 50, or all below 50. This is probably wrong"
      end
      return error_message.blank? ? [success_message, false] : [error_message, true] 
    end

    def wins_and_losses_equals_two_times_vote_count(question)
      error_message   = ""
      success_message = "Wins and losses equals 2 times vote count"
      return [success_message, false] if @question_ids_with_votes_before_2010_02_17.include?(question.id)
      totals = Question.connection.select_one("
        SELECT SUM(wins + losses) AS total,
               SUM(wins) AS total_wins,
               SUM(losses) AS total_losses FROM choices
         WHERE question_id = #{question.id}")
      if(totals["total"].to_i != 2* question.votes_count)
        error_message = "Question #{question.id}: Total votes != 2 x # vote objects, total: #{totals["total"]}, vote_count: #{question.votes_count}"
      end
      return error_message.blank? ? [success_message, false] : [error_message, true] 
    end

    def wins_and_losses_is_even(question)
      error_message   = ""
      success_message = "Total Votes is even"
      return [success_message, false] if @question_ids_with_votes_before_2010_02_17.include?(question.id)
      totals = Question.connection.select_one("
        SELECT SUM(wins + losses) AS total,
               SUM(wins) AS total_wins,
               SUM(losses) AS total_losses FROM choices
         WHERE question_id = #{question.id}")
      if (!totals["total"].blank? && totals["total"].to_i % 2 != 0)
        error_message = "Question #{question.id}: Total votes is not even: #{totals["total"]}"
      end
      return error_message.blank? ? [success_message, false] : [error_message, true] 
    end

    def wins_and_losses_equals_two_times_wins(question)
      error_message   = ""
      success_message = "2 x Total Wins == Total Votes"
      return [success_message, false] if @question_ids_with_votes_before_2010_02_17.include?(question.id)
      totals = Question.connection.select_one("
        SELECT SUM(wins + losses) AS total,
               SUM(wins) AS total_wins,
               SUM(losses) AS total_losses FROM choices
         WHERE question_id = #{question.id}")
      if (2*totals["total_wins"].to_i != totals["total"].to_i)
        error_message = "Question #{question.id}: 2 x Total Wins != Total votes. wins: #{2*totals["total_wins"].to_i}, total: #{totals["total"].to_i}"
      end
      return error_message.blank? ? [success_message, false] : [error_message, true] 
    end

    def answered_appearances_equals_votes_and_skips(question)
      error_message   = ""
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
        error_message = "Question #{question.id}: answered_appearances = #{total_answered_appearances}, votes = #{total_votes}, skips = #{total_skips}"
      end

      return error_message.blank? ? [success_message, false] : [error_message, true] 
    end

    def check_each_choice_appears_within_n_stddevs(question)
      error_message   = ""
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

      if sum > 0
        stddev = Math.sqrt( appearances_by_choice_id.values.inject(0) { |sum, e| sum + (e - mean) ** 2 } / appearances_by_choice_id.size.to_f )

        # add small number to standard deviation to give some leniency when stddev is low
        stddev += 0.5

        # this choice appears to have been deactivated then reactivated after
        # a period of voting
        ignore_choices = [133189]
        appearances_by_choice_id.each do |choice_id, n_i| 
          if ((n_i < (mean - 6*stddev)) || (n_i > mean + 6 *stddev)) && !ignore_choices.include?(choice_id) && Choice.find(choice_id).active?
            error_message = "Choice #{choice_id} in Question ##{question.id} has an irregular number of appearances: #{n_i}, as compared to the mean: #{mean} and stddev #{stddev} for this question\n"
          end
        end
      end

      return error_message.blank? ? [success_message, false] : [error_message, true] 
    end

    def check_each_choice_equally_likely_to_appear_left_or_right(question)
      error_message   = ""
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
          error_message = "Error: Choice ID #{c.id} seems to favor one side: Left Appearances #{left_appearances}, Right Appearances: #{right_appearances}, z = #{z}\n"
        end
      end
      return error_message.blank? ? [success_message, false] : [error_message, true] 
    end
    def check_prompt_cache_hit_rate(question)
      error_message = ""
      success_message = "At least 90% of prompts on catchup algorithm questions were served from cache\n" 
      return [success_message, false] unless question.uses_catchup?

      yesterday = Time.now.utc.yesterday.to_date
      misses = question.get_prompt_cache_misses(yesterday).to_i
      hits = question.get_prompt_cache_hits(yesterday).to_i

      question.expire_prompt_cache_tracking_keys(yesterday)

      yesterday_appearances = Appearance.count_with_exclusive_scope(:conditions => ['created_at >= ? AND created_at < ? AND question_id = ?', Time.now.utc.yesterday.midnight, Time.now.utc.midnight, question.id])

      if misses + hits != yesterday_appearances
        error_message += "Error! Question #{question.id} isn't tracking prompt cache hits and misses accurately! Expected #{yesterday_appearances}, Actual: #{misses+hits}, Hits: #{hits}, Misses: #{misses}\n"
      end

      if yesterday_appearances > 25 # this test isn't worthwhile for small numbers of appearances
        miss_rate = misses.to_f / yesterday_appearances.to_f
        if miss_rate > 0.1
          error_message += "Warning! Question #{question.id} has less than 90% of appearances taken from a pre-generated cache! Expected <#{0.1}, Actual: #{miss_rate}, total appearances yesterday: #{yesterday_appearances}\n"
        end
      end
      return error_message.blank? ? [success_message, false] : [error_message, true] 
    end

    def check_prompt_counter_cache(question)
      error_message = ""
      success_message = "Prompt counter cache equals prompt count in database"

      # Checks that counter_cache is working as expected
      cached_prompts_size = question.prompts.size
      actual_prompts_size = question.prompts.count

      if cached_prompts_size != actual_prompts_size
        error_message = "Error! Question #{question.id} has an inconsistent # of prompts! cached#: #{cached_prompts_size}, actual#: #{actual_prompts_size}\n"
      end
      return error_message.blank? ? [success_message, false] : [error_message, true] 
    end

    def check_vote_counter_cache(question)
      error_message = ""
      success_message = "Vote counter cache equals vote count in database"

      # Checks that counter_cache is working as expected
      cached_votes_size = question.votes.size
      actual_votes_size = question.votes.count

      if cached_votes_size != actual_votes_size
        error_message = "Error! Question #{question.id} has an inconsistent # of votes! cached#: #{cached_votes_size}, actual#: #{actual_votes_size}\n"
      end
      return error_message.blank? ? [success_message, false] : [error_message, true] 
    end

    def check_choice_counter_cache(question)
      error_message = ""
      success_message = "Choice counter cache equals choice count in database"

      # Checks that counter_cache is working as expected
      cached_choices_size = question.choices.size
      actual_choices_size = question.choices.count

      if cached_choices_size != actual_choices_size
        error_message = "Error! Question #{question.id} has an inconsistent # of choices! cached#: #{cached_choices_size}, actual#: #{actual_choices_size}\n"
      end
      return error_message.blank? ? [success_message, false] : [error_message, true] 
    end
  end

  # END OF QUESTION NAMESPACE

  namespace :global do
    @global_tasks = {
      :response_time_tests => "Verify all vote objects have accurate response time",
      :verify_appearance_vote_prompt_ids => "Ensure all appearance and votes have matching prompt_ids",
      :verify_range_of_choices_scores => "Ensure that all choices have 0 <= score <= 100"
    }

    # dynamically create tasks for each global task
    @global_tasks.each do |taskname, description|
      desc description
      task taskname => :environment do
        # call task
        puts send(taskname).inspect
      end
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
      error_message   = ""
      success_message = "All choices have a score within 0-100"
      if bad_choices_count > 0
        error_message = "Some choices have a score less than 0 or greater than 100"
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
          the_error_msg = "Error! Vote #{v.id} was created before the appearance associated with it: Appearance id: #{v.appearance.id}, Vote creation time: #{v.created_at.to_s}, Appearance creation time: #{v.appearance.created_at.to_s}\n\n"

          error_message += the_error_msg
          print "Error!" + the_error_msg
        end

        if v.time_viewed && v.time_viewed/1000 > server_response_time 
          the_error_msg = "Warning! Vote #{v.id} with Appearance #{v.appearance.id}, has a longer client response time than is possible. Server roundtrip time is: #{v.created_at.to_f - v.appearance.created_at.to_f} seconds, but client side response time is: #{v.time_viewed.to_f / 1000.0} seconds\n\n"

          error_message += the_error_msg
          print the_error_msg

        elsif v.time_viewed.nil?
          if v.created_at > recording_client_time_start_date && v.missing_response_time_exp != 'invalid'
            the_error_msg = "Error! Vote #{v.id} with Appearance #{v.appearance.id}, does not have a client response, even though it should! Vote creation time: #{v.created_at.to_s}, Appearance creation time: #{v.appearance.created_at.to_s}, Client side response time: #{v.time_viewed}\n\n"
            error_message += the_error_msg
            print the_error_msg
          end

        end

      end

      return error_message.blank? ? [success_message, false] : [error_message, true] 
    end
  end
  # END OF GLOBAL NAMESPACE

  # votes before 2010-02-17 have null loser_choice_id therefore we
  # want to ignore some tests for any question with votes before 2010-02-17
  desc "Get all question_ids before 2010_02_17"
  task :question_ids_with_votes_before_2010_02_17 => :environment do
    @question_ids_with_votes_before_2010_02_17 = Vote.find(:all, :select => "DISTINCT(question_id)", :conditions => ["created_at < ?", '2010-02-17']).map {|v| v.question_id}
    
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

def debug(message)
  return unless ENV['debug'] == 'true'
  if defined?(Rails)
    logger = AuditLogger.new(STDOUT)
    logger.info(message)
  end
end
