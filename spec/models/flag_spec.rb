require 'spec_helper'

describe Flag do
  it {should belong_to :question}
  it {should belong_to :choice}
  it {should belong_to :site}
  it {should belong_to :visitor}
  it {should validate_presence_of :choice_id}
  it {should validate_presence_of :question_id}

  before(:each) do
    @valid_attributes = {
      :explanation => "value for explanation",
      :visitor_id => 1,
      :choice_id => 1,
      :question_id => 1,
      :site_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    Flag.create!(@valid_attributes)
  end
end
