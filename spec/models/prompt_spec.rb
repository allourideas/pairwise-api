require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Prompt do
  it {should belong_to :question}
  it {should belong_to :left_choice}
  it {should belong_to :right_choice}
  
  before(:each) do
    @aoi_clone = Factory.create(:user, :email => "pius@alum.mit.edu", :password => "password", :password_confirmation => "password", :id => 8)
    @johndoe = Factory.create(:visitor, :identifier => 'johndoe', :site => @aoi_clone)
    @question = Factory.create(:question, :name => 'which do you like better?', :site => @aoi_clone, :creator => @aoi_clone.default_visitor)
    @lc = Factory.create(:choice, :question => @question, :creator => @johndoe, :data => 'hello gorgeous')
    @rc = Factory.create(:choice, :question => @question, :creator => @johndoe, :data => 'goodbye gorgeous')
    @prompt = Factory.create(:prompt, :question => @question, :tracking => 'sample', :left_choice => @lc, :right_choice => @rc)
    @valid_attributes = {
     :left_choice => @lc,
     :right_choice => @rc,
     :question => @question
      
    }
  end

  it "should create a new instance given valid attributes" do

  end
end
