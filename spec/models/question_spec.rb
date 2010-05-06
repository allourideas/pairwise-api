require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Question do
  
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
    @aoi_clone = Factory.create(:user, :email => "pius@alum.mit.edu", :password => "password", :password_confirmation => "password", :id => 8)
    @valid_attributes = {
      :site => @aoi_clone,
      :creator => @aoi_clone.default_visitor
      
    }
    
  end

  it "should create a new instance given valid attributes" do
    Question.create!(@valid_attributes)
  end
  
  it "should be creatable by a user" do
    q = @aoi_clone.create_question("foobarbaz", {:name => 'foo'})
  end
  
  it "should create two default choices if none are provided" do
    q = @aoi_clone.create_question("foobarbaz", {:name => 'foo'})
    q.choices(true).size.should == 2
  end
  
  it "should generate prompts after choices are added" do
    q = @aoi_clone.create_question("foobarbaz", {:name => 'foo'})
    q.prompts(true).size.should == 2
  end

  it "should choose an active prompt randomly" do
    q = @aoi_clone.create_question("foobarbaz", {:name => 'foo'})
    prompt = q.picked_prompt
    prompt.active?.should == true
  end

  it "should choose an active prompt using catchup algorithm" do 
    q = @aoi_clone.create_question("foobarbaz", {:name => 'foo'})
    prompt = q.catchup_choose_prompt
    prompt.active?.should == true
  end

  
  context "catchup algorithm" do 
	  before(:all) do
		  user = Factory.create(:user)
		  @catchup_q = Factory.create(:aoi_question, :site => user, :creator => user.default_visitor)

		  @catchup_q.it_should_autoactivate_ideas = true
		  @catchup_q.save!

		  100.times.each do |num|
			  user.create_choice("visitor identifier", @catchup_q, {:data => num, :local_identifier => "exmaple"})
		  end
	  end
	  it "should choose an active prompt using catchup algorithm on a large number of choices" do 
		  @catchup_q.reload
		  # Sanity check, 2 extra choices are autocreated when empty question created
		  @catchup_q.choices.size.should == 102

		  #the catchup algorithm depends on all prompts being generated automatically
		  @catchup_q.prompts.size.should == 102 **2 - 102

		  prompt = @catchup_q.catchup_choose_prompt
		  prompt.active?.should == true
	  end

	  it "should have a normalized vector of weights to support the catchup algorithm" do
		  weights = @catchup_q.catchup_prompts_weights
		  sum = 0
		  weights.each{|k,v| sum+=v}

		  (sum - 1.0).abs.should < 0.000001
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
	  it "should return prompts from the queue in FIFO order" do
		  @catchup_q.clear_prompt_queue
		  @catchup_q.pop_prompt_queue.should == nil
		  
		  prompt1 = @catchup_q.add_prompt_to_queue
		  prompt2 = @catchup_q.add_prompt_to_queue
		  prompt3 = @catchup_q.add_prompt_to_queue

		  prompt_1 = @catchup_q.pop_prompt_queue
		  prompt_2 = @catchup_q.pop_prompt_queue
		  prompt_3 = @catchup_q.pop_prompt_queue


		  prompt_1.should == prompt1
		  prompt_2.should == prompt2
		  prompt_3.should == prompt3

		  # there is a small probability that the catchup algorithm
		  # choose two prompts that are indeed equal
		  prompt_1.should_not == prompt_2
		  prompt_1.should_not == prompt_3
		  prompt_2.should_not == prompt_3


		  @catchup_q.pop_prompt_queue.should == nil
	  end
  end

  context "exporting data" do
	  before(:each) do
		  user = Factory.create(:user)
		  @question = Factory.create(:aoi_question, :site => user, :creator => user.default_visitor)

	  end
	  

	  it "should export vote data to a csv file" do
		  filename = @question.export('votes')

		  filename.should_not be nil
		  filename.should match /.*ideamarketplace_#{@question.id}_votes[.]csv$/
		  File.exists?(filename).should be_true
		  # Not specifying exact file syntax, it's likely to change frequently
		  #
		  rows = FasterCSV.read(filename)
		  rows.first.should include("Vote ID")
		  rows.first.should_not include("Idea ID")
		  File.delete(filename).should be_true

	  end

	  it "should notify redis after completing an export, if redis option set" do
		  redis_key = "test_key123"
		  $redis.del(redis_key) # clear if key exists already
		  filename = @question.export('votes', :response_type => 'redis', :redis_key => redis_key)

		  filename.should_not be nil
		  filename.should match /.*ideamarketplace_#{@question.id}_votes[.]csv$/
		  File.exists?(filename).should be_true
		  $redis.lpop(redis_key).should == filename

		  # Not specifying exact file syntax, it's likely to change frequently
		  $redis.del(redis_key) # clean up

	  end
	  it "should email question owner after completing an export, if email option set" do
		  #TODO 
	  end

	  it "should export skip data to a csv file" do 
		  filename = @question.export('skips')

		  filename.should_not be nil
		  filename.should match /.*ideamarketplace_#{@question.id}_skips[.]csv$/
		  File.exists?(filename).should be_true

		  # Not specifying exact file syntax, it's likely to change frequently
		  #
		  rows = FasterCSV.read(filename)
		  rows.first.should include("Skip ID")
		  rows.first.should_not include("Idea ID")
		  File.delete(filename).should_not be_nil 


	  end

	  it "should export idea data to a csv file" do
		  filename = @question.export('ideas')

		  filename.should_not be nil
		  filename.should match /.*ideamarketplace_#{@question.id}_ideas[.]csv$/
		  File.exists?(filename).should be_true
		  # Not specifying exact file syntax, it's likely to change frequently
		  #
		  rows = FasterCSV.read(filename)
		  rows.first.should include("Idea ID")
		  rows.first.should_not include("Skip ID")
		  File.delete(filename).should_not be_nil

	  end

	  it "should raise an error when given an unsupported export type" do
		  lambda { @question.export("blahblahblah") }.should raise_error
	  end

	  it "should export data and schedule a job to delete export after X days" do
		  Delayed::Job.delete_all
		  filename = @question.export_and_delete('votes', :delete_at => 2.days.from_now)

		  Delayed::Job.count.should == 1
		  Delayed::Job.delete_all
		  File.delete(filename).should_not be_nil

	  end

  end

end
