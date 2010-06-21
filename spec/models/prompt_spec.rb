require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Prompt do
  it {should belong_to :question}
  it {should belong_to :left_choice}
  it {should belong_to :right_choice}
  before(:each) do
     @question = Factory.create(:aoi_question)
     @prompt = @question.prompts.first
  end

  it "should display left choice text" do
     @prompt.left_choice_text.should == @prompt.left_choice.data
  end
  
  it "should display right choice text" do
     @prompt.right_choice_text.should == @prompt.right_choice.data
  end
end
