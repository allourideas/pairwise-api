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
       sign_in_as(@user = Factory(:email_confirmed_user))
     end
  # 
     def mock_question(stubs={})
       @mock_question ||= mock_model(Question, stubs)
     end
     
     def mock_prompt(stubs={})
       @mock_prompt ||= mock_model(Prompt, stubs)
     end
     
     def mock_appearance(stubs={})
       @mock_appearance||= mock_model(Appearance, stubs)
     end
     
     def mock_visitor(stubs={})
       @mock_visitor||= mock_model(Visitor, stubs)
     end
  # 
  #   describe "GET index" do
  #     it "assigns all questions as @questions" do
  #       Question.stub!(:find).with(:all).and_return([mock_question])
  #       get :index
  #       assigns[:questions].should == [mock_question]
  #     end
  #   end
  # 
     describe "GET show normal" do
       before(:each) do
         Question.stub!(:find).with("37").and_return(mock_question)
       end


       it "assigns the requested question as @question" do
         Question.stub!(:find).with("37").and_return(mock_question)
	 mock_question.should_receive(:choose_prompt).and_return(mock_prompt)
	 #TODO it shouldn't call this unless we are generating an appearance, right?

         get :show, :id => "37"
         assigns[:question].should equal(mock_question)
         assigns[:p].should equal(mock_prompt)
         assigns[:a].should be_nil
       end

       
       it "does not create an appearance when the 'barebones' param is set" do
         get :show, :id => "37", :barebones => true
         assigns[:question].should equal(mock_question)
         assigns[:p].should be_nil
         assigns[:a].should be_nil
       end

       describe "creates an appearance" do
	       before(:each) do
		       @visitor_identifier = "somelongunique32charstring"
		       #stub broken
		       visitor_list = [mock_visitor]
		       @user.stub!(:visitors).and_return(visitor_list)
		       visitor_list.stub!(:find_or_create_by_identifier).and_return(mock_visitor)
		       @user.stub!(:record_appearance).with(mock_visitor, mock_prompt).and_return(mock_appearance)
	       end

	       #TODO this is not a particularly intutive param to pass in order to create an appearance
	       it "creates an appearance when a visitor identifier is a param" do
	              mock_question.should_receive(:choose_prompt).and_return(mock_prompt)
		       get :show, :id => "37", :visitor_identifier => @visitor_identifier
		       assigns[:question].should equal(mock_question)
		       assigns[:p].should equal(mock_prompt)
		       assigns[:a].should equal(mock_appearance)

	       end

	       it "does not create an appearance when the 'barebones' param is set, even when a visitor id is sent" do
		       get :show, :id => "37", :barebones => true, :visitor_identifier => @visitor_identifier
		       assigns[:question].should equal(mock_question)
		       assigns[:p].should be_nil
		       assigns[:a].should be_nil
	       end

	       describe "calls catchup algorithm" do

		       #TODO Refactor out to use uses_catchup?
		       it "should pop prompt from cached queue using the catchup algorithm if params dictate" do
	                       mock_question.should_receive(:choose_prompt).with(:algorithm => "catchup").and_return(mock_prompt)

			       get :show, :id => "37", :visitor_identifier => @visitor_identifier, :algorithm => "catchup"
			       assigns[:question].should equal(mock_question)
			       assigns[:p].should equal(mock_prompt)
			       assigns[:a].should equal(mock_appearance)
		       end

		       it "should handle cache misses gracefully" do
	                       mock_question.should_receive(:choose_prompt).with(:algorithm => "catchup").and_return(mock_prompt)

			       get :show, :id => "37", :visitor_identifier => @visitor_identifier, :algorithm => "catchup"
			       assigns[:question].should equal(mock_question)
			       assigns[:p].should equal(mock_prompt)
			       assigns[:a].should equal(mock_appearance)
		       end
	       end
       end
     end
     
  
end
