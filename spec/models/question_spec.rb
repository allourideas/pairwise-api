require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Question do
  include DBSupport

  it {should belong_to :creator}
  it {should belong_to :site}
  it {should have_many :choices}
  it {should have_many :prompts}
  it {should have_many :votes}
  it {should have_many :densities}
  it {should have_many :appearances}
  it {should validate_presence_of :site}
  it {should validate_presence_of :creator}
  
  before(:each) do
    @question = Factory.create(:aoi_question)
    @aoi_clone = @question.site
  end
  
  it "should have 2 active choices" do
    @question.choices.active.reload.size.should == 2
  end

  it "should report median votes per session" do
    aoiquestion = Factory.create(:aoi_question)
    prompt = aoiquestion.prompts.first
    Factory.create(:vote, :question => aoiquestion, :prompt => prompt)
    Factory.create(:vote, :question => aoiquestion, :prompt => prompt)
    aoiquestion.votes_per_session.should == [{:voter_id => aoiquestion.creator.id, :total => 2}]
    aoiquestion.median_votes_per_session.should == 2
  end

  it "should create a new revision if modified" do
    oldVer = @question.version
    @question.name = "some new name"
    @question.save
    @question.version.should == oldVer + 1
  end

  it "should create a new instance given valid attributes" do
    # Factory.attributes_for does not return associations, this is a good enough substitute
    Question.create!(Factory.build(:question).attributes.symbolize_keys)
  end
  
  it "should not create two default choices if none are provided" do
    q = @aoi_clone.create_question("foobarbaz", {:name => 'foo'})
    q.choices(true).size.should == 0
  end
  
  #it "should generate prompts after choices are added" do
    #@question.prompts(true).size.should == 2
  #end

  it "should choose an active prompt randomly" do
    prompt = @question.simple_random_choose_prompt
    prompt.active?.should == true
  end

  it "should randomly choose two active choices" do
    50.times do
      choice_ids = @question.distinct_array_of_choice_ids(:rank => 2, :only_active => true)
      choice_ids.count.should == 2
      choice_ids.uniq.count.should == 2
      choice_ids.each do |choice_id|
        c = Choice.find(choice_id)
        c.active?.should == true
      end
    end
    
  end

  it "should choose an active prompt using catchup algorithm" do 
    prompt = @question.catchup_choose_prompt(1).first
    prompt.active?.should == true
  end

  it "should raise runtime exception if there is no possible prompt to choose" do
    @question.choices.active.each{|c| c.deactivate!}
    @question.reload
    lambda { @question.choose_prompt}.should raise_error(RuntimeError)

  end

  it "should return nil if optional parameters are empty" do 
    @question_optional_information = @question.get_optional_information(nil)
    @question_optional_information.should be_empty
  end

  it "should return nil if optional parameters are nil" do
    params = {"id" => '37'}
    @question_optional_information = @question.get_optional_information(params)
    @question_optional_information.should be_empty
  end

  it "should return a hash with an prompt id when optional parameters contains 'with_prompt'" do 
    params = {:id => 124, :with_prompt => true}
    @question_optional_information = @question.get_optional_information(params)
    @question_optional_information.should include(:picked_prompt_id) 
    @question_optional_information[:picked_prompt_id].should be_an_instance_of(Fixnum)
  end

  it "should return a hash with an appearance hash when optional parameters contains 'with_appearance'" do
    params = {:id => 124, :with_prompt => true, :with_appearance=> true, :visitor_identifier => 'jim'}
    @question_optional_information = @question.get_optional_information(params)
    @question_optional_information.should include(:appearance_id) 
    @question_optional_information[:appearance_id].should be_an_instance_of(String)
  end

  it "should return a hash with two visitor stats when optional parameters contains 'with_visitor_stats'" do
    params = {:id => 124, :with_visitor_stats=> true, :visitor_identifier => "jim"}
    @question_optional_information = @question.get_optional_information(params)
    @question_optional_information.should include(:visitor_votes) 
    @question_optional_information.should include(:visitor_ideas) 
    @question_optional_information[:visitor_votes].should be_an_instance_of(Fixnum)
    @question_optional_information[:visitor_ideas].should be_an_instance_of(Fixnum)
  end
  
  it "should return a hash when optional parameters have more than one optional param " do
    params = {:id => 124, :with_visitor_stats=> true, :visitor_identifier => "jim", :with_prompt => true, :with_appearance => true}
    @question_optional_information = @question.get_optional_information(params)
    @question_optional_information.should include(:visitor_votes) 
    @question_optional_information.should include(:visitor_ideas) 
    @question_optional_information[:visitor_votes].should be_an_instance_of(Fixnum)
    @question_optional_information[:visitor_ideas].should be_an_instance_of(Fixnum)
    @question_optional_information.should include(:picked_prompt_id) 
    @question_optional_information[:picked_prompt_id].should be_an_instance_of(Fixnum)
    @question_optional_information.should include(:appearance_id) 
    @question_optional_information[:appearance_id].should be_an_instance_of(String)
  end
  
  it "should return the same appearance when a visitor requests two prompts without voting" do
    params = {:id => 124, :with_visitor_stats=> true, :visitor_identifier => "jim", :with_prompt => true, :with_appearance => true}
    @question_optional_information = @question.get_optional_information(params)
    @question_optional_information[:appearance_id].should be_an_instance_of(String)
    @question_optional_information[:picked_prompt_id].should be_an_instance_of(Fixnum)
    saved_appearance_id = @question_optional_information[:appearance_id]
    saved_prompt_id = @question_optional_information[:picked_prompt_id]

    @question_optional_information = @question.get_optional_information(params)
    @question_optional_information[:appearance_id].should == saved_appearance_id
    @question_optional_information[:picked_prompt_id].should == saved_prompt_id
  end
  
  it "should return future prompts for a given visitor when future prompt param is passed" do
    params = {:id => 124, :visitor_identifier => "jim", :with_prompt => true, :with_appearance => true, :future_prompts => {:number => 1} }
    @question_optional_information = @question.get_optional_information(params)
    appearance_id= @question_optional_information[:appearance_id]
    future_appearance_id_1 = @question_optional_information[:future_appearance_id_1]
    future_prompt_id_1 = @question_optional_information[:future_prompt_id_1]
    
    #check that required attributes are included 
    appearance_id.should be_an_instance_of(String)
    future_appearance_id_1.should be_an_instance_of(String)
    future_prompt_id_1.should be_an_instance_of(Fixnum)

    #appearances should have unique lookups
    appearance_id.should_not == future_appearance_id_1
    # check that all required parameters for choices are available

    ['left', 'right'].each do |side|
       ['text', 'id'].each do |param|
         the_type = (param == 'text') ? String : Fixnum
         @question_optional_information["future_#{side}_choice_#{param}_1".to_sym].should be_an_instance_of(the_type)
       end
    end

  end
  
  it "should return the same appearance for future prompts when future prompt param is passed" do
    params = {:id => 124, :visitor_identifier => "jim", :with_prompt => true, :with_appearance => true, :future_prompts => {:number => 1} }
    @question_optional_information = @question.get_optional_information(params)
    saved_appearance_id = @question_optional_information[:appearance_id]
    saved_future_appearance_id_1 = @question_optional_information[:future_appearance_id_1]
    
    @question_optional_information = @question.get_optional_information(params)
    @question_optional_information[:appearance_id].should == saved_appearance_id
    @question_optional_information[:future_appearance_id_1].should == saved_future_appearance_id_1
  end
  
  it "should return the next future appearance in future prompts sequence after a vote is made" do
    params = {:id => 124, :visitor_identifier => "jim", :with_prompt => true, :with_appearance => true, :future_prompts => {:number => 1} }
    @question_optional_information = @question.get_optional_information(params)
    appearance_id = @question_optional_information[:appearance_id]
    prompt_id = @question_optional_information[:picked_prompt_id]
    future_appearance_id_1 = @question_optional_information[:future_appearance_id_1]
    future_prompt_id_1 = @question_optional_information[:future_prompt_id_1]
    
    vote_options = {:visitor_identifier => "jim",
        :appearance_lookup => appearance_id,
        :prompt => Prompt.find(prompt_id),
        :direction => "left"}

    @aoi_clone.record_vote(vote_options)
    
    @question_optional_information = @question.get_optional_information(params)
    @question_optional_information[:appearance_id].should_not == appearance_id
    @question_optional_information[:appearance_id].should == future_appearance_id_1
    @question_optional_information[:picked_prompt_id].should == future_prompt_id_1
    @question_optional_information[:future_appearance_id_1].should_not == future_appearance_id_1
  end
  
  it "should provide average voter information" do
    params = {:id => 124, :visitor_identifier => "jim", :with_prompt => true, :with_appearance => true, :with_average_votes => true }
    @question_optional_information = @question.get_optional_information(params)
    @question_optional_information[:average_votes].should be_an_instance_of(Fixnum)
    @question_optional_information[:average_votes].should be_close(0.0, 0.1)
    
    vote_options = {:visitor_identifier => "jim",
        :appearance_lookup => @question_optional_information[:appearance_id],
        :prompt => Prompt.find(@question_optional_information[:picked_prompt_id]),
        :direction => "left"}

    @aoi_clone.record_vote(vote_options)
    @question_optional_information = @question.get_optional_information(params)
    @question_optional_information[:average_votes].should be_close(1.0, 0.1)
  end
  
  it "should properly handle tracking the prompt cache hit rate when returning the same appearance when a visitor requests two prompts without voting" do
    params = {:id => 124, :with_visitor_stats=> true, :visitor_identifier => "jim", :with_prompt => true, :with_appearance => true}
    @question.clear_prompt_queue
    @question.reset_cache_tracking_keys(Date.today)
    @question.get_optional_information(params)
    @question.get_prompt_cache_misses(Date.today).should == "1"
    @question.get_optional_information(params)
    @question.get_prompt_cache_misses(Date.today).should == "1"
  end
  
  it "should auto create ideas when 'ideas' attribute is set" do
      @question = Factory.build(:question)
      @question.ideas = %w(one two three)
      @question.save
      @question.choices.count.should == 3
  end

  it "should create 500 ideas question without creating any prompts" do
      @question = Factory.build(:question)
      @question.ideas = []
      o = [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
      500.times do
        @question.ideas << (0..10).map{ o[rand(o.length)]  }.join
      end

      @question.save
      @question.choices.count.should == 500

      @question.reload.prompts.count.should == 0
  end

  context "median response per session" do
    before(:all) do
      truncate_all
      @q = Factory.create(:aoi_question)
    end

    it "should properly calculate with no responses" do
      @q.median_responses_per_session.should == nil
    end

    it "should properly calculate with 2 sessions" do
      # one session with 1 vote, one with 2 votes
      Factory.create(:vote_new_user, :question => @q)
      v = Factory.create(:vote_new_user, :question => @q)
      Factory.create(:vote, :question => @q, :voter => v.voter)
      @q.median_responses_per_session.should == 1.5
    end

    it "should properly calculate with 3 sessions" do
      # one session with 3 skips, 2 votes
      v = Factory.create(:vote_new_user, :question => @q)
      3.times { Factory.create(:skip, :question => @q, :skipper => v.voter) }
      Factory.create(:vote, :question => @q, :voter => v.voter)

      # second session with 3 skips
      v = Factory.create(:skip_new_user, :question => @q)
      2.times { Factory.create(:skip, :question => @q, :skipper => v.skipper) }

      # third session with 4 votes, 5 skips
      v = Factory.create(:vote_new_user, :question => @q)
      3.times { Factory.create(:skip, :question => @q, :skipper => v.voter) }
      4.times { Factory.create(:vote, :question => @q, :voter => v.voter) }
      @q.median_responses_per_session.should == 5
    end
  end

  context "votes per uploaded choice" do
    before(:all) do
      truncate_all
      @q = Factory.create(:aoi_question)
    end
    it "should be calculated properly with no uploaded choices" do
      @q.votes_per_uploaded_choice.should == nil
      @q.votes_per_uploaded_choice(true).should == nil
    end

    it "should be calculated properly with some choices and votes" do
        v = Factory.create(:vote_new_user, :question => @q)
        Factory.create(:choice, :creator => v.voter, :question => @q)
        Factory.create(:choice, :creator => v.voter, :question => @q, :active => true)
        4.times { Factory.create(:vote, :question => @q, :voter => v.voter) }
        @q.votes_per_uploaded_choice.should == 2.5
        @q.votes_per_uploaded_choice(true).should == 5.0
    end
  end

  context "rate of uploaded ideas to participation" do
    before(:all) do
      truncate_all
      @q = Factory.create(:aoi_question)
    end
    it "should give proper stats required for idea:participation rate" do
      @q.sessions_with_uploaded_ideas.should == 0
      @q.sessions_with_participation.should == 0
      @q.upload_to_participation_rate.should == nil

      # 10 voting only sessions
      10.times { Factory.create(:vote_new_user, :question => @q) }
      @q.sessions_with_uploaded_ideas.should == 0
      @q.sessions_with_participation.should == 10
      @q.upload_to_participation_rate.should == 0.0

      # 7 users who voted and added ideas
      7.times do
        v = Factory.create(:vote_new_user, :question => @q)
        Factory.create(:choice, :creator => v.voter, :question => @q)
      end
      @q.sessions_with_uploaded_ideas.should == 7
      @q.sessions_with_participation.should == 17
      @q.upload_to_participation_rate.round(3).should == 0.412

      # 2 users who only skip
      2.times { Factory.create(:skip_new_user, :question => @q) }
      @q.sessions_with_uploaded_ideas.should == 7
      @q.sessions_with_participation.should == 19
      @q.upload_to_participation_rate.round(3).should == 0.368

      # 3 users who did everything
      3.times do
        v = Factory.create(:vote_new_user, :question => @q)
        Factory.create(:choice, :creator => v.voter, :question => @q)
        Factory.create(:skip, :skipper => v.voter, :question => @q)
      end
      @q.sessions_with_uploaded_ideas.should == 10
      @q.sessions_with_participation.should == 22
      @q.upload_to_participation_rate.round(3).should == 0.455

      # 5 users who only added ideas
      5.times { Factory.create(:choice_new_user, :question => @q) }
      @q.sessions_with_uploaded_ideas.should == 15
      @q.sessions_with_participation.should == 27
      @q.upload_to_participation_rate.round(3).should == 0.556

    end
  end

  context "sessions_with_vote" do
    before(:all) do
      truncate_all
      @q1 = Factory.create(:aoi_question)
      @q2 = Factory.create(:aoi_question)
    end

    it "should not count sessions for another question" do
      Factory.create(:vote, :question => @q1)
      appearance = Factory.create(:appearance_new_user, :question => @q1)
      Factory.create(:vote_new_user, :question => @q2, :voter => appearance.voter)
      @q1.sessions_with_vote.should == 1
    end

  end
  context "vote rate" do
    before(:all) do
      truncate_all
      @q = Factory.create(:aoi_question)
    end

    it "should give proper stats required for vote rate" do
      @q.total_uniq_sessions.should == 0
      @q.sessions_with_vote.should == 0
      @q.vote_rate.should == nil

      # add new session + appearance, but no vote
      Factory.create(:appearance_new_user, :question => @q)
      @q.total_uniq_sessions.should == 1
      @q.sessions_with_vote.should == 0
      @q.vote_rate.should == 0.0

      # add new vote + session
      Factory.create(:vote, :question => @q)
      Factory.create(:vote, :question => @q)
      Factory.create(:vote, :question => @q)
      @q.total_uniq_sessions.should == 2
      @q.sessions_with_vote.should == 1
      @q.vote_rate.should == 0.5

      # add new session + appearance, but no vote
      Factory.create(:appearance_new_user, :question => @q)
      @q.total_uniq_sessions.should == 3
      @q.sessions_with_vote.should == 1
      @q.vote_rate.should == (1.to_f / 3.to_f)

      # add new session + appearance, but no vote
      Factory.create(:appearance_new_user, :question => @q)
      @q.total_uniq_sessions.should == 4
      @q.sessions_with_vote.should == 1
      @q.vote_rate.should == 0.25

      # add new vote + session
      v = Factory.create(:vote_new_user, :question => @q)
      @q.total_uniq_sessions.should == 5
      @q.sessions_with_vote.should == 2
      @q.vote_rate.should == 0.4
    end
  end
  context "catchup algorithm" do 
    before(:all) do
      @catchup_q = Factory.create(:aoi_question)

      @catchup_q.it_should_autoactivate_ideas = true
      @catchup_q.uses_catchup = true
      @catchup_q.save!

      # 4 ideas already exist, so this will make an even hundred
      96.times.each do |num|
        @catchup_q.site.create_choice("visitor identifier", @catchup_q, {:data => num.to_s, :local_identifier => "exmaple"})
      end
      @catchup_q.reload
    end


    it "should create a delayed job after requesting a prompt" do
      proc { @catchup_q.choose_prompt}.should change(Delayed::Job, :count).by(1)
    end


    it "should choose an active prompt using catchup algorithm on a large number of choices" do 
      @catchup_q.reload
      # Sanity check
      @catchup_q.choices.size.should == 100

      prompt = @catchup_q.catchup_choose_prompt(1).first
      prompt.active?.should == true
    end

    it "should have a normalized vector of weights to support the catchup algorithm" do
      weights = @catchup_q.catchup_prompts_weights
      sum = 0
      weights.each{|k,v| sum+=v}

      (sum - 1.0).abs.should < 0.000001
    end

    it "should not have any inactive choices in the the vector of weights" do
      weights = @catchup_q.catchup_prompts_weights
      weights.each do |items, value|
        left_choice_id, right_choice_id = items.split(", ")
        cl = Choice.find(left_choice_id)
        cr = Choice.find(right_choice_id)
        cl.active?.should == true
        cr.active?.should == true
      end
    end

    it "should allow the prompt queue to be cleared" do
      @catchup_q.add_prompt_to_queue
      @catchup_q.clear_prompt_queue

      @catchup_q.pop_prompt_queue.should == nil
    end
    it "should allow a prompt to be added to the prompt queue" do
      @catchup_q.clear_prompt_queue
      @catchup_q.pop_prompt_queue.should == nil

      @catchup_q.add_prompt_to_queue

      prompt = @catchup_q.pop_prompt_queue

      prompt.should_not == nil
      prompt.active?.should == true
    end
    it "should not return prompts from queue that are deactivated" do
      @catchup_q.clear_prompt_queue
      @catchup_q.pop_prompt_queue.should == nil
      prompt1 = @catchup_q.add_prompt_to_queue.first
            
      prompt = Prompt.find(prompt1)
      prompt.left_choice.deactivate!
      @catchup_q.choose_prompt.should_not == prompt1 
          end
    after(:all) { truncate_all }
  end

  context "exporting data" do
    before(:all) do
      @aoi_question = Factory.create(:aoi_question)
      user = @aoi_question.site

      @aoi_question.it_should_autoactivate_ideas = true
      @aoi_question.save!

                  visitor = user.visitors.find_or_create_by_identifier('visitor identifier')
      100.times.each do |num|
        user.create_choice(visitor.identifier, @aoi_question, {:data => num.to_s, :local_identifier => "example creator"})
      end

      200.times.each do |num|
        @p = @aoi_question.simple_random_choose_prompt
        @p.active?.should == true

        @a = user.record_appearance(visitor, @p)

        vote_options = {:visitor_identifier => visitor.identifier,
            :appearance_lookup => @a.lookup,
            :prompt => @p,
            :time_viewed => rand(1000),
            :direction => (rand(2) == 0) ? "left" : "right"}
        
                          skip_options = {:visitor_identifier => visitor.identifier,
                                          :appearance_lookup => @a.lookup,
                                          :prompt => @p,
                                          :time_viewed => rand(1000),
                                          :skip_reason => "some reason"}

        choice = rand(3)
        case choice
        when 0
          user.record_vote(vote_options)
        when 1
          user.record_skip(skip_options)
        when 2
           #this is an orphaned appearance, so do nothing
        end
      end
    end
    

    it "should export vote data to a csv file" do
      csv = @aoi_question.export('votes')

      # Not specifying exact file syntax, it's likely to change frequently
      #
      rows = FasterCSV.parse(csv)
      rows.first.should include("Vote ID")
      rows.first.should_not include("Idea ID")

    end

    it "should export zlibed csv to redis after completing an export, if redis option set" do
      redis_key = "test_key123"
      $redis.del(redis_key) # clear if key exists already
      csv = @aoi_question.export('votes')
      @aoi_question.export('votes', :response_type => 'redis', :redis_key => redis_key)

      zlibcsv = $redis.lpop(redis_key)
      zstream = Zlib::Inflate.new
      buf = zstream.inflate(zlibcsv)
      zstream.finish
      zstream.close
      buf.should == csv
      $redis.del(redis_key) # clean up

    end
    it "should email question owner after completing an export, if email option set" do
      #TODO 
    end

    it "should export non vote data to a string" do 
      csv = @aoi_question.export('non_votes')

      rows = FasterCSV.parse(csv)
      rows.first.should include("Record ID")
      rows.first.should include("Record Type")
      rows.first.should_not include("Idea ID")
      # ensure we have more than just the header row
      rows.length.should be > 1
    end

    it "should export idea data to a string" do
      csv = @aoi_question.export('ideas')

      # Not specifying exact file syntax, it's likely to change frequently
      #
      rows = FasterCSV.parse(csv)
      rows.first.should include("Idea ID")
      rows.first.should_not include("Skip ID")
    end

    it "should raise an error when given an unsupported export type" do
      lambda { @aoi_question.export("blahblahblah") }.should raise_error
    end

    after(:all) { truncate_all }
  end

  context "exporting data with odd characters" do
    before(:all) do
      @aoi_question = Factory.create(:question)
      user = @aoi_question.site

      @aoi_question.it_should_autoactivate_ideas = true
      @aoi_question.save!

      visitor = user.visitors.find_or_create_by_identifier('visitor identifier')

      user.create_choice(visitor.identifier, @aoi_question,
          {:data => "foo\nbar", :local_identifier => "example creator"})
      user.create_choice(visitor.identifier, @aoi_question,
          {:data => "foo,bar", :local_identifier => "example creator"})
      user.create_choice(visitor.identifier, @aoi_question,
          {:data => "foo\"bar", :local_identifier => "example creator"})
      user.create_choice(visitor.identifier, @aoi_question,
          {:data => "foo'bar", :local_identifier => "example creator"})

      40.times.each do |num|
        @p = @aoi_question.simple_random_choose_prompt
        @p.active?.should == true

        @a = user.record_appearance(visitor, @p)

        vote_options = {:visitor_identifier => visitor.identifier,
            :appearance_lookup => @a.lookup,
            :prompt => @p,
            :time_viewed => rand(1000),
            :direction => (rand(2) == 0) ? "left" : "right"
        }
        
        skip_options = {:visitor_identifier => visitor.identifier,
                        :appearance_lookup => @a.lookup,
                        :prompt => @p,
                        :time_viewed => rand(1000),
                        :skip_reason => "some reason"
        }

        choice = rand(3)
        case choice
        when 0
          user.record_vote(vote_options)
        when 1
          user.record_skip(skip_options)
        when 2
           #this is an orphaned appearance, so do nothing
        end
      end
    end

    it "should export idea data to a string with proper escaping" do
      csv = @aoi_question.export('ideas')

      # Not specifying exact file syntax, it's likely to change frequently
      #
      rows = FasterCSV.parse(csv)
      rows.first.should include("Idea ID")
      rows.first.should_not include("Skip ID")

      rows.shift
      rows.each do |row|
        # Idea Text
        row[2].should =~ /^foo.bar$/m
      end
    end

    it "should export vote data to a string with proper escaping" do
      csv = @aoi_question.export('votes')

      # Not specifying exact file syntax, it's likely to change frequently
      #
      rows = FasterCSV.parse(csv)
      rows.first.should include("Vote ID")
      rows.first.should_not include("Idea ID")

      rows.shift
      rows.each do |row|
        # Winner Text
        row[4].should =~ /^foo.bar$/m
        # Loser Text
        row[6].should =~ /^foo.bar$/m
      end

    end

    after(:all) { truncate_all }
  end

end
