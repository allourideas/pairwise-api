require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe QuestionsController do
  
     def sign_in_as(user)
       @controller.current_user = user
       return user
     end

     before(:each) do
        @question = Factory.create(:aoi_question)
        sign_in_as(@user = @question.site)
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

     it "can be set to autoactivate questions" do
       put :set_autoactivate_ideas_from_abroad, :id => @question.id, :format => "xml", :question => {:it_should_autoactivate_ideas => true}
       assigns[:question].should == @question
       assigns[:question].it_should_autoactivate_ideas.should be_true
       @response.body.should == "true"
     end
  
end
