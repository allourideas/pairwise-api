require 'spec_helper'

describe Appearance do
  before(:each) do
    @valid_attributes = {
      :voter_id => ,
      :site_id => ,
      :prompt_id => ,
      :question_id => ,
      :vote_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    Appearance.create!(@valid_attributes)
  end
end
