require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Visitor do
  
  it {should belong_to :site}
  it {should have_many :questions}
  it {should have_many :votes}
  it {should have_many :skips}
  it {should have_many :clicks}
  it {should have_many :appearances}
  
  before(:each) do
    @question = Factory.create(:aoi_question)
    @aoi_clone = @question.site

    @prompt = @question.prompts.first
    @visitor = @aoi_clone.visitors.find_or_create_by_identifier("test_visitor_identifier")
    
    @required_vote_params = {:prompt => @prompt, 
                            :direction => "left"}
  end

  it "should create a new instance given valid attributes" do
     Visitor.create!(Factory.build(:visitor).attributes.symbolize_keys)
  end
  
  it "should be able to determine ownership of a question" do
    @visitor.owns?(Question.new).should be_false
    @visitor.owns?(Factory.build(:aoi_question)).should be_false
    
    @johndoe = Factory.create(:visitor)
    ownedquestion = Factory.create(:question, :site => @aoi_clone, :creator=> @johndoe)
    @johndoe.owns?(ownedquestion).should be_true
  end
  
  it "should be able to vote for a prompt" do
    @prompt.votes.size.should == 0

    v = @visitor.vote_for!(@required_vote_params)
    v.should_not be_nil

    v.prompt.should == @prompt
    v.choice.should == @prompt.left_choice
    v.loser_choice.should == @prompt.right_choice
    v.voter.should == @visitor
    @prompt.reload
    @prompt.votes.size.should  == 1
  end
  
  it "should be able to vote for a choice" do
    @required_vote_params[:direction] = "right"
    v = @visitor.vote_for!(@required_vote_params)
    v.should_not be_nil

    v.prompt.should == @prompt
    v.choice.should == @prompt.right_choice
    v.loser_choice.should == @prompt.left_choice
    @prompt.right_choice.reload
    @prompt.right_choice.votes.size.should  == 1
  end

  it "should return nil when no prompt is provided" do
    @required_vote_params.delete(:prompt)
    v = @visitor.vote_for!(@required_vote_params)
    v.should be_nil
    @prompt.reload
    @prompt.votes.size.should == 0
    @question.reload
    @question.votes.size.should == 0
  end
  it "should return nil when no direction is provided" do
    @required_vote_params.delete(:direction)
    v = @visitor.vote_for!(@required_vote_params)
    v.should be_nil
    @prompt.reload
    @prompt.votes.size.should == 0
    @question.reload
    @question.votes.size.should == 0
  end

  it "should keep track of optional vote attributes" do
    @appearance = @aoi_clone.record_appearance(@visitor, @prompt)
    @optional_vote_params = {:appearance_lookup => @appearance.lookup,
		            :time_viewed => 213}
    
    allparams = @required_vote_params.merge(@optional_vote_params)
    v = @visitor.vote_for!(allparams)

    v.appearance.should == @appearance
    v.time_viewed.should == 213
    
  end
  
  it "should be able to skip a prompt" do
    @appearance = @aoi_clone.record_appearance(@visitor, @prompt)
    s = @visitor.skip! @appearance.lookup, @prompt, 304
  end

  it "should accurately update score counts after vote" do
   
    @lc = @prompt.left_choice
    @rc = @prompt.right_choice
   
    prev_winner_score = @lc.score
    prev_loser_score = @rc.score
    
    vote = @visitor.vote_for! @required_vote_params
    
    @lc.reload
    @rc.reload

    @lc.score.should > prev_winner_score
    @rc.score.should < prev_loser_score
  end
  
  it "should accurately update win and loss totals after vote" do
    @lc = @prompt.left_choice
    @rc = @prompt.right_choice
    prev_winner_wins = @lc.wins
    prev_winner_losses = @lc.losses
    prev_loser_losses = @rc.losses
    prev_loser_wins = @rc.wins
    
    vote = @visitor.vote_for! @required_vote_params
    
    @lc.reload
    @rc.reload

    @lc.wins.should == prev_winner_wins + 1
    @lc.losses.should == prev_winner_losses
    @rc.losses.should ==  prev_loser_losses + 1
    @rc.wins.should ==  prev_winner_wins
  end

    
end
