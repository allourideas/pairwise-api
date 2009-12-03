require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Skip do
  it {should belong_to :prompt}
  it {should belong_to :skipper}
  before(:each) do
    @valid_attributes = {
      
    }
  end

  it "should create a new instance given valid attributes" do
    Skip.create!(@valid_attributes)
  end
end
