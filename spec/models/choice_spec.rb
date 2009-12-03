require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Choice do
  
  it {should belong_to :question}
  it {should belong_to :item}
  it {should validate_presence_of :question}
  
  before(:each) do
    @aoi_clone = Factory.create(:user, :email => "pius@alum.mit.edu", :password => "password", :password_confirmation => "password", :id => 8)
    @johndoe = Factory.create(:visitor, :identifier => 'johndoe', :site => @aoi_clone)
    @question = Question.create(:name => 'which do you like better?', :site => @aoi_clone, :creator => @johndoe)
    
    @valid_attributes = {
      :creator => @johndoe,
      :question => @question,
      :data => 'hi there'
    }
  end

  it "should create a new instance given valid attributes" do
    Choice.create!(@valid_attributes)
  end
  
  it "should generate prompts after creation" do
    @question.prompts.should_not be_empty
    choice1 = Choice.create!(@valid_attributes.merge(:data => '1234'))
    @question.prompts.should_not be_empty
  end
end
