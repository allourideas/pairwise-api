require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe QuestionsController do
  
     def sign_in_as(user)
       @controller.current_user = user
       return user
     end

     before(:each) do
        @question = Factory.create(:aoi_question)
        sign_in_as(@user = @question.site)
	@creator = @question.creator
     end
     it "responds with basic question information" do
         get :show, :id => @question.id, :format => "xml"

         assigns[:question].should == @question
	 @response.body.should have_tag("question")
	 @response.code.should == "200"
     end


     it "responds with question with prompt and appearance and visitor information" do 
         get :show, :id => @question.id, :format => "xml", :with_appearance => true, :with_prompt => true, :with_visitor_stats => true, :visitor_identifier => "jim"

         assigns[:question].should == @question
	 #@response.body.should be_nil
	 @response.code.should == "200"
	 @response.body.should have_tag("question")
	 @response.body.should have_tag("picked_prompt_id")
	 @response.body.should have_tag("appearance_id")
	 @response.body.should have_tag("visitor_votes")
	 @response.body.should have_tag("visitor_ideas")

     end
  
end
