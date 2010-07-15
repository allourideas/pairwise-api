require 'spec_helper'

describe Appearance do
  before(:each) do
  end
  
  it {should belong_to :voter}
  it {should belong_to :prompt}
  it {should belong_to :question}
  it {should belong_to :answerable}

  it "should create a new instance given valid attributes" do
    Appearance.create!(@valid_attributes)
  end
  it "should mark voted upon appearances as answered == true" do 
    @appearance = Appearance.create!(@valid_attributes)
    @vote = Factory.create(:vote, :appearance => @appearance)
    @appearance.should be_answered
  end
  it "should mark voted upon appearances as answered == true" do 
    @appearance = Appearance.create!(@valid_attributes)
    @skip = Skip.create!(:appearance => @appearance)
    @appearance.should be_answered
  end
end
