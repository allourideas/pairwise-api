require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Visitor do
  
  it {should belong_to :site}
  it {should have_many :questions}
  it {should have_many :votes}
  it {should have_many :skips}
  it {should have_many :clicks}
  it {should have_many :appearances}
  it {should have_many :choices}
  
  before(:each) do
    @question = Factory.create(:aoi_question)
    @aoi_clone = @question.site

    @prompt = @question.prompts.first
    @visitor = @aoi_clone.visitors.find_or_create_by_identifier("test_visitor_identifier")
    
    @required_vote_params = {:prompt => @prompt, 
                            :direction => "left"}
    @required_skip_params = {:prompt => @prompt}
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

  it "should not create a new appearance if the answers's visitor is different from the appearance's" do
    # test for both a vote and a skip
    ['vote', 'skip'].each do |answer|
      @appearance = @aoi_clone.record_appearance(@visitor, @prompt)
      appearance_param = {:appearance_lookup => @appearance.lookup}

      @johndoe = Factory.create(:visitor)
      a = nil
      if answer == 'skip'
        a = @johndoe.skip!(@required_skip_params.merge(appearance_param))
        a.should == nil
      else
        a = @johndoe.vote_for!(@required_vote_params.merge(appearance_param))
        a.should == nil
      end
      @appearance.answerable.should == nil

    end
  end

  it "should not accept a vote on a previously answered prompt if vote has different visitor" do
    # test for both a vote and a skip
    ['vote', 'skip'].each do |answer|
      @appearance = @aoi_clone.record_appearance(@visitor, @prompt)
      appearance_param = {:appearance_lookup => @appearance.lookup}

      @johndoe = Factory.create(:visitor)
      jd_appearance_param = appearance_param.merge({:old_visitor_identifier => @visitor.identifier})

      first_vote = @visitor.vote_for!(@required_vote_params.merge(appearance_param))
      invalid_answer = nil
      visitor_votes_prev = @visitor.reload.votes.count
      votes_prev = @question.reload.votes.size
      skips_prev = @question.skips.size
      if answer == 'skip'
        invalid_answer = @johndoe.skip!(@required_skip_params.merge(jd_appearance_param))
        invalid_answer.class.should == Skip
      else
        invalid_answer = @johndoe.vote_for!(@required_vote_params.merge(jd_appearance_param))
        invalid_answer.class.should == Vote
      end

      first_vote.appearance.should == @appearance

      invalid_answer.should_not be_nil

      invalid_answer.valid_record.should be_false
      invalid_answer.validity_information.should == "Appearance #{@appearance.id} already answered"
      invalid_answer.appearance.should be_nil
      @appearance.reload.answerable.should == first_vote
      @visitor.reload.votes.count.should == visitor_votes_prev
      @question.reload.votes.size.should == votes_prev  #test counter cache works as well
      @question.reload.skips.size.should == skips_prev  #test counter cache works as well
    end
  end

  it "should create a new appearance if the answer's visitor is different from the appearance's and the answer passed in the old_visitor_identifier" do
    # test for both a vote and a skip
    ['vote', 'skip'].each do |answer|
      @appearance = @aoi_clone.record_appearance(@visitor, @prompt)
      appearance_param = { :appearance_lookup => @appearance.lookup }

      @johndoe = Factory.create(:visitor)
      jd_appearance_param = appearance_param.merge({:old_visitor_identifier => @visitor.identifier})
      a = nil
      if answer == "skip"
        a = @johndoe.skip!(@required_skip_params.merge(jd_appearance_param))
        a.class.should == Skip
      else
        a = @johndoe.vote_for!(@required_vote_params.merge(jd_appearance_param))
        a.class.should == Vote
      end
      new_appearance = a.appearance

      new_appearance.should_not == @appearance
      new_appearance.id.should_not == @appearance.id
      new_appearance.answerable_id.should_not == @appearance.answerable_id
      new_appearance.answerable_type.should_not == @appearance.answerable_type
      new_appearance.prompt_id.should == @appearance.prompt_id
      new_appearance.question_id.should == @appearance.question_id
      new_appearance.lookup.should == @appearance.lookup
      new_appearance.voter_id.should == @johndoe.id
      @appearance.answerable_id.should be_nil
      @appearance.answerable_type.should be_nil
    end
  end
  
  it "should be able to skip a prompt" do
    @appearance = @aoi_clone.record_appearance(@visitor, @prompt)
    @optional_skip_params = {
      :appearance_lookup => @appearance.lookup,
      :time_viewed => 304,
      :skip_reason => "some reason"
    }
    allparams = @required_skip_params.merge(@optional_skip_params)
    s = @visitor.skip!(allparams)
    s.appearance.should == @appearance
  end
  
  it "should not create a skip when the appearance look up is wrong" do
    skip_count = Skip.count
    @appearance = @aoi_clone.record_appearance(@visitor, @prompt)
    @optional_skip_params = {
      :appearance_lookup => "not a valid appearancelookup",
      :time_viewed => 304,
      :skip_reason => "some reason"
    }
    allparams = @required_skip_params.merge(@optional_skip_params)
    s = @visitor.skip!(allparams)
    s.should be_nil
    Skip.count.should == skip_count
  end
  
  it "should mark a skip as invalid if submitted with an already answered appearance" do
    @appearance = @aoi_clone.record_appearance(@visitor, @prompt)
    @optional_skip_params = {:appearance_lookup => @appearance.lookup} 
    allparams = @required_skip_params.merge(@optional_skip_params)

    valid_skip = @visitor.skip!(allparams)
    @visitor.skips.count.should == 1
    @visitor.skips.size.should == 1
    @appearance.reload.answerable.should == valid_skip

    # we need to reset because vote_for deletes keys from the params
    allparams = @required_skip_params.merge(@optional_skip_params)
    invalid_skip = @visitor.skip!(allparams)
    invalid_skip.should_not be_nil

    invalid_skip.valid_record.should be_false
    invalid_skip.validity_information.should == "Appearance #{@appearance.id} already answered"
    @appearance.reload.answerable.should == valid_skip
    @visitor.reload.skips.count.should == 1
    @visitor.reload.skips.size.should == 1
  end

  it "should mark a vote as invalid if submitted with an already answered appearance" do
    @appearance = @aoi_clone.record_appearance(@visitor, @prompt)
    @optional_vote_params = {:appearance_lookup => @appearance.lookup} 
    allparams = @required_vote_params.merge(@optional_vote_params)

    valid_vote = @visitor.vote_for!(allparams)
    @visitor.votes.count.should == 1
    @question.reload.votes.size.should == 1
    @appearance.reload.answerable.should == valid_vote

    # we need to reset because vote_for deletes keys from the params
    allparams = @required_vote_params.merge(@optional_vote_params)
    invalid_vote = @visitor.vote_for!(allparams)
    invalid_vote.should_not be_nil

    invalid_vote.valid_record.should be_false
    invalid_vote.validity_information.should == "Appearance #{@appearance.id} already answered"
    @appearance.reload.answerable.should == valid_vote
    @visitor.reload.votes.count.should == 1
    @question.reload.votes.size.should == 1  #test counter cache works as well
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
  
  it "should invalidate vote after skips when :skip_fraud_protection option passed" do
    
    # If a visitor skips a prompt, the vote after should be conisdered invalid
    @appearance = @aoi_clone.record_appearance(@visitor, @prompt)
    @visitor.skip!(@required_skip_params.merge({ :appearance_lookup => @appearance.lookup}))

    @appearance_2 = @aoi_clone.record_appearance(@visitor, @prompt)
    @optional_vote_params = {:appearance_lookup => @appearance_2.lookup, :skip_fraud_protection => true }

    vote = @visitor.vote_for! @required_vote_params.merge(@optional_vote_params)
    vote.valid_record.should be_false
    
    @appearance_3 = @aoi_clone.record_appearance(@visitor, @prompt)
    @optional_vote_params = {:appearance_lookup => @appearance_3.lookup, :skip_fraud_protection => true }
    
    vote_2 = @visitor.vote_for! @required_vote_params.merge(@optional_vote_params)

    vote_2.valid_record.should be_true

  end

    
end
