require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Item do
  it {should belong_to :creator}
  it {should belong_to :site}
  
  before(:each) do
    @aoi_clone = Factory.create(:user, :email => "pius@alum.mit.edu", :password => "password", :password_confirmation => "password", :id => 8)
    @johndoe = Factory.create(:visitor, :identifier => 'johndoe', :site => @aoi_clone)
    @valid_attributes = {
      :site => @aoi_clone,
      :creator => @johndoe
    }
  end

  it "should create a new instance given valid attributes" do
    Item.create!(@valid_attributes)
  end
end
