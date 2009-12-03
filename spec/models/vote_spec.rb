require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Vote do
  before(:each) do
    @valid_attributes = {
      :tracking => "value for tracking",
      :site_id => 1,
      :voter_id => 1,
      :voteable_id => 1,
      :voteable_type => "value for voteable_type"
    }
  end

  it "should create a new instance given valid attributes" do
    Vote.create!(@valid_attributes)
  end
end
