require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Question do
  
  it {should belong_to :creator}
  it {should belong_to :site}
  it {should have_many :choices}
  it {should have_many :prompts}
  it {should validate_presence_of :site}
  
  before(:each) do
    @aoi_clone = Factory.create(:user, :email => "pius@alum.mit.edu", :password => "password", :password_confirmation => "password", :id => 8)
    @valid_attributes = {
      :site => @aoi_clone,
      :creator => @aoi_clone.default_visitor
      
    }
    
    #    @item1 = Factory.create(:item, :data => "foo", :id => 1, :creator_id => 8)
    #    @item2 = Factory.create(:item, :data => "bar", :id => 2, :creator_id => 8)
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
  
  #q = @aoi_clone.create_question("foobarbaz", {:name => 'foo'})
end