require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe QuestionsController do
  
  # integrate_views
  #   
     def sign_in_as(user)
       @controller.current_user = user
       return user
     end
  #   
     before(:each) do
        @user = Factory.create(:user, :email => "pius@alum.mit.edu", :password => "password", :password_confirmation => "password", :id => 8)
        sign_in_as(@user = Factory(:email_confirmed_user))
        @question = @user.create_question("foobarbaz", {:name => 'foo'})
     end
     it "responds with basic question information" do
         get :show, :id => @question.id, :format => "xml"

         assigns[:question].should == @question
	 @response.body.should have_tag("question")
     end


     it "responds with question with prompt and appearance and visitor information" do 
         get :show, :id => @question.id, :format => "xml", :with_appearance => true, :with_prompt => true, :with_visitor_stats => true, :visitor_identifier => "jim"

         assigns[:question].should == @question
	 #@response.body.should be_nil
	 @response.body.should have_tag("question")
	 @response.body.should have_tag("picked_prompt_id")
	 @response.body.should have_tag("appearance_id")
	 @response.body.should have_tag("visitor_votes")
	 @response.body.should have_tag("visitor_ideas")

     end
  
end
