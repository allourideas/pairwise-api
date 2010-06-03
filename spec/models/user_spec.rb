require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do
  it {should have_many :visitors}

  before(:each) do
    @aoi_clone = Factory.create(:user)
    @question = Factory.create(:aoi_question)
    @prompt = @question.prompts.first

  end

  
  it "should be able to create a question as a site" do
    q = @aoi_clone.create_question("foobarbaz", {:name => 'foo'})
    q.should_not be_nil
    q.site.should_not be_nil
    q.site.should eql @aoi_clone
  end
  
  it "should be able to create a choice for a question " do
    q = @aoi_clone.create_question("foobarbaz", {:name => 'foo'}) #replace with a factory
    c = @aoi_clone.create_choice("foobarbaz", q, {:data => 'foobarbaz'})
    q.should_not be_nil
    q.choices.should_not be_empty
    q.choices.size.should eql 1
  end
  
  it "should be able to record a visitor's vote" do
    @visitor = @aoi_clone.visitors.find_or_create_by_identifier("test_visitor_identifier")
    @appearance = @aoi_clone.record_appearance(@visitor, @prompt)
    v = @aoi_clone.record_vote("johnnydoe", @appearance.lookup, @prompt, 0, 304)
    prompt_votes = @prompt.votes(true)
    prompt_votes.should_not be_empty
    prompt_votes.size.should eql 1
    
    choices = @prompt.choices
    #@question.prompts(true).size.should == 2
    choices.should_not be_empty
    
    choice_votes = choices[0].votes(true)
    choice_votes.should_not be_empty
    choice_votes.size.should eql 1
  end
  
  it "should be able to record a visitor's skip" do
    @visitor = @aoi_clone.visitors.find_or_create_by_identifier("test_visitor_identifier")
    @appearance = @aoi_clone.record_appearance(@visitor, @prompt)
    s = @aoi_clone.record_skip("johnnydoe", @appearance.lookup, @prompt, 340)
  end

end
