require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Vote do
  it {should belong_to :voter}
  it {should belong_to :question}
  it {should belong_to :prompt}
  it {should belong_to :choice}
  it {should belong_to :loser_choice}
  it {should have_one :appearance}

  before(:each) do
    @question = Factory.create(:aoi_question)
    @prompt = @question.prompts.first
  end

  it "should create a new instance with factory girl" do
    Factory.create(:vote)
  end

  it "should update counter cache on question" do
    @question.votes.size.should == 0
    @question.votes_count.should == 0
    Factory.create(:vote, :question => @question)

    @question.reload
    @question.votes.size.should == 1
    @question.votes_count.should == 1
    
  end
  it "should update counter cache on prompt" do
    @prompt.votes.size.should == 0
    @prompt.votes_count.should == 0
    Factory.create(:vote, :question => @question, :prompt => @prompt)

    @prompt.reload
    @prompt.votes.size.should == 1
    @prompt.votes_count.should == 1
  end
  it "should update counter cache on choice" do
    @prompt.left_choice.votes.size.should == 0
    @prompt.left_choice.wins.should == 0
    Factory.create(:vote, :question => @question, :prompt => @prompt, 
                          :choice => @prompt.left_choice)

    @prompt.left_choice.reload
    @prompt.left_choice.votes.size.should == 1
    @prompt.left_choice.wins.should == 1
  end
  it "should update counter cache on loser_choice" do
    @prompt.left_choice.votes.size.should == 0
    @prompt.right_choice.losses.should == 0
    @prompt.left_choice.wins.should == 0
    Factory.create(:vote, :question => @question, :prompt => @prompt,
                          :choice => @prompt.left_choice,
                          :loser_choice => @prompt.right_choice)


    @prompt.right_choice.reload
    @prompt.right_choice.votes.size.should == 0
    @prompt.right_choice.wins.should == 0
    @prompt.right_choice.losses.should == 1
  end

  it "should update score of winner choice after create" do 
    @prompt.left_choice.score.should == 50
    Factory.create(:vote, :question => @question, :prompt => @prompt, 
                          :choice => @prompt.left_choice)

    @prompt.left_choice.reload
    @prompt.left_choice.score.should be_close 67, 1
  end
  
  it "should update score of loser choice after create" do 
    @prompt.left_choice.score.should == 50
    Factory.create(:vote, :question => @question, :prompt => @prompt,
                          :choice => @prompt.left_choice,
                          :loser_choice => @prompt.right_choice)

    @prompt.right_choice.reload
    @prompt.right_choice.score.should be_close 33, 1
  end
  
  it "should not display invalid votes by default" do 
    5.times do
       Factory.create(:vote)
    end
    Vote.count.should == 5

    v = Vote.last
    v.valid_record.should be_true

    v.valid_record = false
    v.save
    Vote.count.should == 4
  end
  
  it "should allow default valid_record behavior to be overriden by default" do
     required_params = {:question => @question, :prompt => @prompt,
                          :choice => @prompt.left_choice,
                          :voter=> @question.site.default_visitor,
                          :loser_choice => @prompt.right_choice}

     vote = Vote.create!(required_params)
     vote.valid_record.should be_true
     
     
     vote = Vote.create!(required_params.merge!(:valid_record => false))
     vote.valid_record.should be_false
  end
end
