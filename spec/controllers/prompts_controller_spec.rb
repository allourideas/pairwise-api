require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PromptsController do
   def sign_in_as(user)
     @controller.current_user = user
     return user
   end
  #   
   before(:each) do
    @question = Factory.create(:aoi_question)
    sign_in_as(@aoi_clone = @question.site)
    @prompt = @question.prompts.first
    
    @visitor = @aoi_clone.visitors.find_or_create_by_identifier("test_visitor_identifier")
    @appearance = @aoi_clone.record_appearance(@visitor, @prompt)
   end
  # 

#  describe "GET index" do
#    it "assigns all prompts as @prompts" do
#      Question.stub!(:find).with(:all).and_return(@question)
#      Question.stub!(:prompts).with(:all).and_return([mock_prompt])
#      get :index, :question_id => @question.id
#      assigns[:prompts].should == [@prompt]
#    end
#  end

  describe "GET show" do
    it "assigns the requested prompt as @prompt" do
      get :show, :id => @prompt.id, :question_id => @question.id
      assigns[:prompt].should == @prompt
    end
  end
  
  describe "POST skip" do
    it "records a skip, responds with next prompt" do
      post :skip, :id => @prompt.id, :question_id => @question.id, :params => {:auto => @visitor, :time_viewed => 30, :appearance_lookup => @appearance.lookup}
      assigns[:next_prompt].should_not == @prompt
      assigns[:next_prompt].should_not be_nil
      assigns[:a].should_not be_nil
      assigns[:a].should_not == @appearance
      assigns[:skip].should_not be_nil
    end
  end

end
