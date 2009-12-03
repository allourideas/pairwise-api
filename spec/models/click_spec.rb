require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Click do
  
  it {should belong_to :visitor}
  it {should belong_to :site}
  
  before(:each) do
    @valid_attributes = {
      :site_id => 1,
      :visitor_id => 1,
      :additional_info => "value for additional_info"
    }
  end

  it "should create a new instance given valid attributes" do
    Click.create!(@valid_attributes)
  end
end
