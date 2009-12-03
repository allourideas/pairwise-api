require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Visitor do
  
  it {should belong_to :site}
  it {should have_many :questions}
  it {should have_many :votes}
  it {should have_many :skips}
  
  before(:each) do
    @aoi_clone = Factory.create(:user, :email => "pius@alum.mit.edu", :password => "password", :password_confirmation => "password", :id => 8)
    @johndoe = Factory.create(:visitor, :identifier => 'johndoe', :site => @aoi_clone)
    @question = Factory.create(:question, :name => 'which do you like better?', :site => @aoi_clone, :creator => @aoi_clone.default_visitor)
    @lc = Factory.create(:choice, :question => @question, :creator => @johndoe, :data => 'hello gorgeous')
    @rc = Factory.create(:choice, :question => @question, :creator => @johndoe, :data => 'goodbye gorgeous')
    @prompt = Factory.create(:prompt, :question => @question, :tracking => 'sample', :left_choice => @lc, :right_choice => @rc)
    #my_instance.stub!(:msg).and_return(value)
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
  end
  
  it "should be able to vote for a prompt" do
    #@prompt = @question.prompts.first
    @prompt.should_not be_nil
    v = @v.vote_for! @prompt, 0
  end
  
  it "should be able to vote for a prompt" do
    #@prompt = @question.prompts.first
    @prompt.should_not be_nil
    v = @v.skip! @prompt
  end
    
end
