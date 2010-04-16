require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ChoicesController do

  def mock_choice(stubs={})
    @mock_choice ||= mock_model(Choice, stubs)
  end

  describe "GET index" do
    it "assigns all choices as @choices" do
      Choice.stub!(:find).with(:all).and_return([mock_choice])
      get :index
      assigns[:choices].should == [mock_choice]
    end
  end

  describe "GET show" do
    it "assigns the requested choice as @choice" do
      Choice.stub!(:find).with("37").and_return(mock_choice)
      get :show, :id => "37"
      assigns[:choice].should equal(mock_choice)
    end
  end

  describe "GET new" do
    it "assigns a new choice as @choice" do
      Choice.stub!(:new).and_return(mock_choice)
      get :new
      assigns[:choice].should equal(mock_choice)
    end
  end

  describe "GET edit" do
    it "assigns the requested choice as @choice" do
      Choice.stub!(:find).with("37").and_return(mock_choice)
      get :edit, :id => "37"
      assigns[:choice].should equal(mock_choice)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created choice as @choice" do
        Choice.stub!(:new).with({'these' => 'params'}).and_return(mock_choice(:save => true))
        post :create, :choice => {:these => 'params'}
        assigns[:choice].should equal(mock_choice)
      end

      it "redirects to the created choice" do
        Choice.stub!(:new).and_return(mock_choice(:save => true))
        post :create, :choice => {}
        response.should redirect_to(choice_url(mock_choice))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved choice as @choice" do
        Choice.stub!(:new).with({'these' => 'params'}).and_return(mock_choice(:save => false))
        post :create, :choice => {:these => 'params'}
        assigns[:choice].should equal(mock_choice)
      end

      it "re-renders the 'new' template" do
        Choice.stub!(:new).and_return(mock_choice(:save => false))
        post :create, :choice => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested choice" do
        Choice.should_receive(:find).with("37").and_return(mock_choice)
        mock_choice.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :choice => {:these => 'params'}
      end

      it "assigns the requested choice as @choice" do
        Choice.stub!(:find).and_return(mock_choice(:update_attributes => true))
        put :update, :id => "1"
        assigns[:choice].should equal(mock_choice)
      end

      it "redirects to the choice" do
        Choice.stub!(:find).and_return(mock_choice(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(choice_url(mock_choice))
      end
    end

    describe "with invalid params" do
      it "updates the requested choice" do
        Choice.should_receive(:find).with("37").and_return(mock_choice)
        mock_choice.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :choice => {:these => 'params'}
      end

      it "assigns the choice as @choice" do
        Choice.stub!(:find).and_return(mock_choice(:update_attributes => false))
        put :update, :id => "1"
        assigns[:choice].should equal(mock_choice)
      end

      it "re-renders the 'edit' template" do
        Choice.stub!(:find).and_return(mock_choice(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end
    end

  end


end
