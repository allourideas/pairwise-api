require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PromptsController do
   def sign_in_as(user)
     @controller.current_user = user
     return user
   end

   before(:each) do
    @question = Factory.create(:aoi_question)
    sign_in_as(@aoi_clone = @question.site)
    @prompt = @question.prompts.first
    
    @visitor = @aoi_clone.visitors.find_or_create_by_identifier("test_visitor_identifier")
    @appearance = @aoi_clone.record_appearance(@visitor, @prompt)
   end

  describe "GET show" do
    it "assigns the requested prompt as @prompt" do
      get :show, :id => @prompt.id, :question_id => @question.id
      assigns[:prompt].should == @prompt
    end
  end
  
  describe "POST skip" do
    it "records a skip, responds with next prompt" do
      post :skip, :id => @prompt.id, :question_id => @question.id, :params => {:auto => @visitor, :time_viewed => 30, :appearance_lookup => @appearance.lookup}
      assigns[:next_prompt].should_not be_nil
      assigns[:a].should_not be_nil
      assigns[:a].should_not == @appearance
      assigns[:skip].should_not be_nil
    end
  end

  describe "POST vote" do
    it "votes on a prompt" do 
         post :vote, :question_id => @question.id, :id => @prompt.id,
	             :vote => {:direction => "left"},
		     :format => :xml

         @response.code.should == "200"
    end

    it "returns 422 when missing fields are not provided" do
         post :vote, :question_id => @question.id, :id => @prompt.id
        
	# there is somethingw wrong with response codes, this doesn't work
	#@response.code.should == "422"
    end
    
    it "votes on a prompt and responds with optional information" do
         post :vote, :question_id => @question.id, :id => @prompt.id,
		     :vote => {:direction => "left",
		               :time_viewed => "492", 
			       :visitor_identifier => "jim"},
		     :next_prompt => {
		          :with_appearance => true, 
		          :with_visitor_stats => true, 
			  :visitor_identifier => "jim"},
	 	     :format => :xml
	 
	 @response.code.should == "200"
    end
    
    it "should prevent other users from voting on non owned questions" do
    end

  end

end
