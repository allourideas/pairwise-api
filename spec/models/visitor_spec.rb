require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Visitor do
  
  it {should belong_to :site}
  it {should have_many :questions}
  it {should have_many :votes}
  it {should have_many :skips}
  it {should have_many :clicks}
  
  before(:each) do
    @aoi_clone = Factory.create(:user)
    @johndoe = Factory.create(:visitor, :identifier => 'johndoe', :site => @aoi_clone)
    @question = Factory.create(:question, :name => 'which do you like better?', :site => @aoi_clone, :creator => @aoi_clone.default_visitor)
    @lc = Factory.create(:choice, :question => @question, :creator => @johndoe, :data => 'hello gorgeous')
    @rc = Factory.create(:choice, :question => @question, :creator => @johndoe, :data => 'goodbye gorgeous')
    @prompt = Factory.create(:prompt, :question => @question, :tracking => 'sample', :left_choice => @lc, :right_choice => @rc)
    
    @visitor = @aoi_clone.visitors.find_or_create_by_identifier("test_visitor_identifier")
    @appearance = @aoi_clone.record_appearance(@visitor, @prompt)
    @valid_attributes = {
      :site => @aoi_clone,
      :identifier => "value for identifier",
      :tracking => "value for tracking"
    }
    @v = Visitor.create!(@valid_attributes)

  end

  it "should create a new instance given valid attributes" do
    
  end
  
  it "should be able to determine ownership of a question" do
    @v.owns?(Question.new).should be_false

    ownedquestion = Factory.create(:question, :site => @aoi_clone, :creator=> @johndoe)
    @johndoe.owns?(ownedquestion).should be_true
  end
  
  it "should be able to vote for a prompt" do
    #@prompt = @question.prompts.first
    @prompt.should_not be_nil
    v = @v.vote_for! @appearance.lookup, @prompt, 0, 340
  end
  
  it "should be able to skip a prompt" do
    #@prompt = @question.prompts.first
    @prompt.should_not be_nil
    v = @v.skip! @appearance.lookup, @prompt, 304
  end

  it "should accurately update score counts after vote" do
    prev_winner_score = @lc.score
    prev_loser_score = @rc.score
    
    vote = @v.vote_for! @appearance.lookup, @prompt, 0, 340
    
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
    
    vote = @v.vote_for! @appearance.lookup, @prompt, 0, 340
    
    @lc.reload
    @rc.reload

    @lc.wins.should == prev_winner_wins + 1
    @lc.losses.should == prev_winner_losses
    @rc.losses.should ==  prev_loser_losses + 1
    @rc.wins.should ==  prev_winner_wins
  end

    
end
