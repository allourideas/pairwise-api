require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PromptsController do

  def mock_prompt(stubs={})
    @mock_prompt ||= mock_model(Prompt, stubs)
  end

  before(:each) do 
          @aoi_clone = Factory.create(:user)
          @question = Factory.create(:question, :site => @aoi_clone, :creator => @aoi_clone.default_visitor)
  end

  describe "GET index" do
    it "assigns all prompts as @prompts" do
#      Question.stub!(:find).with(:all).and_return(@question)
#      Question.stub!(:prompts).with(:all).and_return([mock_prompt])
      get :index, :question_id => @question.id
      assigns[:prompts].should == [mock_prompt]
    end
  end

  describe "GET show" do
    it "assigns the requested prompt as @prompt" do
#      Question.stub!(:find).with(:all).and_return(@question)
#      Prompt.stub!(:find).with("37").and_return(mock_prompt)
      get :show, :id => "37", :question_id => @question.id
      assigns[:prompt].should equal(mock_prompt)
    end
  end
end
