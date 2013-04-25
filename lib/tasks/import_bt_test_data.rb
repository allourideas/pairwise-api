require 'faster_csv'

BASEDIR = "/home/dhruv/CITP/bt_test/"

q = Question.new(:name => "test for bt", :creator_id => 1, :site_id => 1)
q.save()

choice_offset = Choice.last.id

inserts = []

timestring = Time.now.to_s(:db) #isn't rails awesome?
totalchoices=0
CSVBridge.foreach(BASEDIR + "choices_7000.txt", {:headers => :first_row, :return_headers => false}) do |choice|
# for each choice, create an insert with unique id
   id = choice[0].to_i + choice_offset
   wins = choice[1].to_i
   inserts.push("(#{q.id}, #{id}, #{wins}, '#{timestring}', '#{timestring}')")
   totalchoices+=1
end

sql = "INSERT INTO `choices` (`question_id`, `item_id`, `votes_count`, `created_at`, `updated_at`) VALUES #{inserts.join(', ')}"

ActiveRecord::Base.connection.execute(sql)

inserts = []
prompt_offset = Prompt.last.id
totalprompts = 0
CSVBridge.foreach(BASEDIR + "prompts_7000.txt", {:headers => :first_row, :return_headers => false}) do |prompt|
   id = prompt[0].to_i + prompt_offset
   left_choice_id = prompt[1].to_i + choice_offset
   right_choice_id = prompt[2].to_i + choice_offset
   votes_count =  prompt[3].to_i

   inserts.push("(NULL, #{q.id}, NULL, #{left_choice_id}, '#{timestring}', '#{timestring}', NULL, #{votes_count}, #{right_choice_id}, NULL, NULL)")
   totalprompts +=1
end

sql = "INSERT INTO `prompts` (`algorithm_id`, `question_id`, `voter_id`, `left_choice_id`, `created_at`, `updated_at`, `tracking`, `votes_count`, `right_choice_id`, `active`, `randomkey`) VALUES #{inserts.join(', ')}"

ActiveRecord::Base.connection.execute(sql)

inserts = []
vote_offset = Vote.last.id
totalvotes=0
CSVBridge.foreach(BASEDIR + "votes_7000.txt", {:headers => :first_row, :return_headers => false}) do |vote|
   id = vote[0].to_i + vote_offset
   prompt_id = vote[1].to_i + prompt_offset 
   choice_id = vote[2].to_i + choice_offset
   loser_choice_id = vote[3].to_i 

   inserts.push("(#{prompt_id}, #{q.id}, #{choice_id}, #{loser_choice_id}, '#{timestring}', '#{timestring}')")
   totalvotes +=1
end

sql = "INSERT INTO `votes` (`prompt_id`, `question_id`, `choice_id`, `loser_choice_id`, `created_at`, `updated_at`) VALUES #{inserts.join(', ')}"

ActiveRecord::Base.connection.execute(sql)

sql = "UPDATE questions SET votes_count=#{totalvotes}, prompts_count=#{totalprompts}, choices_count=#{totalchoices} WHERE id=#{q.id}"

ActiveRecord::Base.connection.execute(sql)
