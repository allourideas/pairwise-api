namespace :timezone do

  # There is a very similar task in the AOI code base as well.
  # Any core changes to this task should probably be reflected there.
  desc "Converts all dates from PT to UTC"
  task :convert_dates_to_utc, [:workerid, :workers] => [:environment] do|t,args|
    args.with_defaults(:workerid => "0", :workers => "1")
    raise "workerid can not be greater than workers" if args[:workerid] > args[:workers]
    time_spans = [
      { :gt => "2009-11-01 01:59:59", :lt => "2010-03-14 02:00:00", :h => 8},
      { :gt => "2010-03-14 01:59:59", :lt => "2010-11-07 01:00:00", :h => 7},
      { :gt => "2010-11-07 00:59:59", :lt => "2010-11-07 02:00:00", :h => nil},
      { :gt => "2010-11-07 01:59:59", :lt => "2011-03-13 02:00:00", :h => 8},
      { :gt => "2011-03-13 01:59:59", :lt => "2011-11-06 01:00:00", :h => 7},
      { :gt => "2011-11-06 00:59:59", :lt => "2011-11-06 02:00:00", :h => nil},
      { :gt => "2011-11-06 01:59:59", :lt => "2012-03-11 02:00:00", :h => 8},
      { :gt => "2012-03-11 01:59:59", :lt => "2012-11-04 01:00:00", :h => 7}
    ]
    unambiguator = {
      :appearances => [
        { :range => 454229..454229, :h => 7},
        { :range => 454426..454501, :h => 7}, # 454501 updated_at needs additional hour
        { :range => 454502..454745, :h => 8},
	      { :range => 4005307..4005522, :h => 7 },
	      { :range => 4005523..4005556, :h => 8 }
      ],
      :choices => [
        { :range => 181957..181957, :h => 7} # based on appearance id 8392753
      ],
      :prompts => [
        { :range => 5191157..5191225, :h => 7},
        { :range => 5191226..5191876, :h => 8},
        { :range => 8392753..8392758, :h => 7}, # based on appearance id 4005361
      ],
      :question_versions => [
        { :range => 7126..7128, :h => 7} # based on choice 181957
      ],
      :questions => [
        { :range => 1855..1855, :h => 7} # based on question_versions 7128
      ],
      :skips => [
        { :range => 30948..30952, :h => 8}, # based on vote 326681
        { :range => 365240..365276, :h => 7},
        { :range => 365277..365281, :h => 8},
      ],
      :visitors => [
        { :range => 594751..594777, :h => 7},
        { :range => 594778..594795, :h => 8},
        { :range => 91350..91358, :h => 7},
        { :range => 91359..91366, :h => 8}
      ],
      :votes => [
        { :range => 3145774..3145926, :h => 7},
        { :range => 3145927..3145935, :h => 8},
        { :range => 326504..326571, :h => 7},
        { :range => 326572..326803, :h => 8},
      ],
    }
    # UTC because Rails will be thinking DB is in UTC when we run this
    #time_spans.map! do |t|
    #  { :gt => Time.parse("#{t[:gt]} UTC"),
    #    :lt => Time.parse("#{t[:lt]} UTC"),
    #    :h  => t[:h] }
    #end
    datetime_fields = {
      #:appearances  => ['created_at', 'updated_at'],
      #:choices      => ['created_at', 'updated_at'],
      #:clicks       => ['created_at', 'updated_at'],
      #:densities    => ['created_at', 'updated_at'],
      #:flags        => ['created_at', 'updated_at'],
      #:prompts      => ['created_at', 'updated_at'],
      :skips        => ['created_at', 'updated_at'],
      #:votes        => ['created_at', 'updated_at'],
      #:visitors     => ['created_at', 'updated_at'],
      #:users        => ['created_at', 'updated_at'],
      #:questions    => ['created_at', 'updated_at'],
      #:question_versions => ['created_at', 'updated_at'],
      #:delayed_jobs => ['created_at', 'updated_at', 'run_at', 'locked_at', 'failed_at'],
    }

    STDOUT.sync = true
    logger = Rails.logger
    datetime_fields.each do |table, columns|
      print "#{table}"
      batch_size = 10000
      i = 0
      where = ''
      # This is how we split the rows of a table between the various workers
      # so that they don't attempt to work on the same row as another worker.
      # The workerid is any number 0 through workers - 1.
      if args[:workers] > "1"
        where = "WHERE MOD(id, #{args[:workers]}) = #{args[:workerid]}"
      end
      while true do
        rows = ActiveRecord::Base.connection.select_all(
          "SELECT id, #{columns.join(", ")} FROM #{table} #{where} ORDER BY id LIMIT #{i*batch_size}, #{batch_size}"
        )
        print "."

        rows.each do |row|
          updated_values = {}
          # delete any value where the value is blank (just for delayed_jobs)
          row.delete_if {|key, value| value.blank? }
          row.each do |column, value|
            next if column == "id"
            time_spans.each do |span|
              if value < span[:lt] && value > span[:gt]
                # if blank then ambiguous and we don't know how to translate
                if span[:h].blank?
                  updated_values[column] = nil
                  if unambiguator[table] && unambiguator[table].length > 0
                    unambiguator[table].each do |ids|
                      updated_values[column] = ids[:h] if ids[:range].include? row["id"].to_i
                    end
                  end

                  logger.info "AMBIGUOUS: #{table} #{row["id"]} #{column}: #{value}" if updated_values[column].blank?
                else
                  updated_values[column] = span[:h]
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
            update = "UPDATE #{table} SET #{updated_values.map{|k,v| "#{k} = DATE_ADD(#{k}, INTERVAL #{v} HOUR)"}.join(", ")} WHERE id = #{row["id"]}"
	    num = ActiveRecord::Base.connection.update_sql(update)
	    if num == 1
              logger.info "UPDATE: #{table} #{row.inspect} #{updated_values.inspect}"
	    else
              logger.info "UPDATE FAILED: #{table} #{row.inspect} #{updated_values.inspect} #{num.inspect}"
	    end
          end
        end

        i+= 1
        break if rows.length < batch_size
      end
      print "\n"
    end
  end

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

end
