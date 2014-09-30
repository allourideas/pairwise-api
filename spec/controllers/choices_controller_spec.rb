require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ChoicesController do
  
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
     
     def mock_choice(stubs={})
       @mock_choice||= mock_model(Choice, stubs)
     end
     
     def mock_flag(stubs={})
       @mock_flag ||= mock_model(Flag, stubs)
     end
     
     def mock_vote(stubs={})
       @mock_vote || mock_model(Vote, stubs)
     end

     describe "PUT flag" do
       before(:each) do
	  question_list = [mock_question]
	  @user.stub!(:questions).and_return(question_list)
	  question_list.stub!(:find).with("37").and_return(mock_question)

	  choice_list = [mock_choice]
	  mock_question.stub!(:choices).and_return(choice_list)
	  choice_list.stub!(:find).with("123").and_return(mock_choice)
	  mock_choice.should_receive(:deactivate!).and_return(true)


       end

       it "deactives a choice when a flag request is sent" do
	    Flag.should_receive(:create!).with({:choice_id => 123, :question_id => 37, :site_id => @user.id})
	    put :flag, :id => 123, :question_id => 37   

	    assigns[:choice].should == mock_choice
       end
       
       it "adds explanation params to flag if sent" do
	    Flag.should_receive(:create!).with({:choice_id => 123, :question_id => 37, :site_id => @user.id, :explanation => "This is offensive"})
	    put :flag, :id => 123, :question_id => 37 , :explanation => "This is offensive"

	    assigns[:choice].should == mock_choice
       end
       
       it "adds visitor_id params to flag if sent" do
	    @visitor_identifier = "somelongunique32charstring"
	    visitor_list = [mock_visitor]
            @user.stub!(:visitors).and_return(visitor_list)
            visitor_list.should_receive(:find_or_create_by_identifier).with(@visitor_identifier).and_return(mock_visitor)

	    Flag.should_receive(:create!).with({:choice_id => 123, :question_id => 37, :site_id => @user.id, :explanation => "This is offensive", :visitor_id => mock_visitor.id})   

	    put :flag, :id => 123, :question_id => 37 , :explanation => "This is offensive", :visitor_identifier => @visitor_identifier

	    assigns[:choice].should == mock_choice
       end

     end
       
     describe "POST create" do
	before(:each) do
		@question = Factory.create(:aoi_question)
                sign_in_as(@user = @question.site)
	end
	
       
       it "creates a choice" do
	       post :create, :question_id => @question.id, :choice => {:data => "blahblah"}
	       assigns[:choice].should_not be_nil
	       assigns[:choice].creator.should == @question.site.default_visitor
	       assigns[:choice].should_not be_active
	       assigns[:choice].should_not be_active
       end

       it "creates a choice with a correct visitor creator" do
	       post :create, :question_id => @question.id, :choice => {:data => "blahblah", :visitor_identifier => "new user"}
	       assigns[:choice].should_not be_nil
	       assigns[:choice].creator.identifier.should == "new user"
	       assigns[:choice].should_not be_active
	       assigns[:choice].user_created.should == true
       end

       it "creates a choice and activates it when set_autoactivate_is set" do
         @question.update_attribute(:it_should_autoactivate_ideas, true)
         post :create, :question_id => @question.id, :choice => {:data => "blahblah"}
         assigns[:choice].should_not be_nil
         assigns[:choice].creator.should == @question.site.default_visitor
         assigns[:choice].should be_active
       end
    end

    describe "GET votes" do
      it "returns a choice's votes" do
        Choice.should_receive(:find).and_return(mock_choice)
        votes_array = [mock_vote]
        votes_array.should_receive(:to_xml)
        mock_choice.should_receive(:votes).and_return(votes_array)

        get :votes, :id => mock_choice.id, :question_id => mock_question.id
      end
    end
  
    describe "GET similar" do
      it "returns all choices with identical data" do
        question = Factory(:question, :site => @user)
        choice = Factory(:choice, :question => question)
        choice1 = choice.clone
        choice1.active = true
        choice2 = choice.clone
        choice2.active = true
        choice3 = choice.clone
        choice1.save
        choice2.save
        choice3.save

        get :similar, :question_id => question.id, :id => choice.id, :format => "xml"

        assigns[:similar].should include(choice1, choice2)
        assigns[:similar].should_not include(choice, choice3)
        response.code.should == "200"
        response.body.should_not have_tag("versions")
      end
    end

    describe "GET show" do
      it "doesn't returns all versions by default" do
        question = Factory(:question, :site => @user)
        choice = Factory(:choice, :question => question)

        get :show, :question_id => question.id, :id => choice.id, :format => "xml"

        response.code.should == "200"
        response.body.should_not have_tag("versions")
      end

      it "responds with all versions if requested" do
        question = Factory(:question, :site => @user)
        choice = Factory(:choice, :question => question)

        get :show, :question_id => question.id, :id => choice.id, :format => "xml", :version => "all"

        response.code.should == "200"
        response.body.should have_tag("versions")
      end
    end
end
