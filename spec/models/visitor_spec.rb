require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Visitor do
  
  it {should belong_to :site}
  it {should have_many :questions}
  it {should have_many :votes}
  it {should have_many :skips}
  it {should have_many :clicks}
  
  before(:each) do
    @question = Factory.create(:aoi_question)
    @aoi_clone = @question.site
    @johndoe = @question.creator

    @prompt = @question.prompts.first
    @lc = @prompt.left_choice
    @rc = @prompt.right_choice
    
    @visitor = @aoi_clone.visitors.find_or_create_by_identifier("test_visitor_identifier")
    @appearance = @aoi_clone.record_appearance(@visitor, @prompt)
    @valid_attributes = {
      :site => @aoi_clone,
      :identifier => "value for identifier",
      :tracking => "value for tracking"
    }
  end

  it "should create a new instance given valid attributes" do
    @visitor = Visitor.create!(@valid_attributes)
    
  end
  
  it "should be able to determine ownership of a question" do
    @visitor.owns?(Question.new).should be_false

    ownedquestion = Factory.create(:question, :site => @aoi_clone, :creator=> @johndoe)
    @johndoe.owns?(ownedquestion).should be_true
  end
  
  it "should be able to vote for a prompt" do
    #@prompt = @question.prompts.first
    @prompt.should_not be_nil
    v = @visitor.vote_for! @appearance.lookup, @prompt, 0, 340
  end
  
  it "should be able to skip a prompt" do
    #@prompt = @question.prompts.first
    @prompt.should_not be_nil
    v = @visitor.skip! @appearance.lookup, @prompt, 304
  end

  it "should accurately update score counts after vote" do
    prev_winner_score = @lc.score
    prev_loser_score = @rc.score
    
    vote = @visitor.vote_for! @appearance.lookup, @prompt, 0, 340
    
    @lc.reload
    @rc.reload

    @lc.score.should > prev_winner_score
    @rc.score.should < prev_loser_score
  end
  
  it "should accurately update win and loss totals after vote" do
    prev_winner_wins = @lc.wins
    prev_winner_losses = @lc.losses
    prev_loser_losses = @rc.losses
    prev_loser_wins = @rc.wins
    
    vote = @visitor.vote_for! @appearance.lookup, @prompt, 0, 340
    
    @lc.reload
    @rc.reload

    @lc.wins.should == prev_winner_wins + 1
    @lc.losses.should == prev_winner_losses
    @rc.losses.should ==  prev_loser_losses + 1
    @rc.wins.should ==  prev_winner_wins
  end

    
end
