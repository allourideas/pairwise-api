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



  end

  
  #q = @aoi_clone.create_question("foobarbaz", {:name => 'foo'})
end
