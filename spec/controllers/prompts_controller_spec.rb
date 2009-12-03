require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PromptsController do

  def mock_prompt(stubs={})
    @mock_prompt ||= mock_model(Prompt, stubs)
  end

  describe "GET index" do
    it "assigns all prompts as @prompts" do
      Prompt.stub!(:find).with(:all).and_return([mock_prompt])
      get :index
      assigns[:prompts].should == [mock_prompt]
    end
  end

  describe "GET show" do
    it "assigns the requested prompt as @prompt" do
      Prompt.stub!(:find).with("37").and_return(mock_prompt)
      get :show, :id => "37"
      assigns[:prompt].should equal(mock_prompt)
    end
  end

  describe "GET new" do
    it "assigns a new prompt as @prompt" do
      Prompt.stub!(:new).and_return(mock_prompt)
      get :new
      assigns[:prompt].should equal(mock_prompt)
    end
  end

  describe "GET edit" do
    it "assigns the requested prompt as @prompt" do
      Prompt.stub!(:find).with("37").and_return(mock_prompt)
      get :edit, :id => "37"
      assigns[:prompt].should equal(mock_prompt)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created prompt as @prompt" do
        Prompt.stub!(:new).with({'these' => 'params'}).and_return(mock_prompt(:save => true))
        post :create, :prompt => {:these => 'params'}
        assigns[:prompt].should equal(mock_prompt)
      end

      it "redirects to the created prompt" do
        Prompt.stub!(:new).and_return(mock_prompt(:save => true))
        post :create, :prompt => {}
        response.should redirect_to(prompt_url(mock_prompt))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved prompt as @prompt" do
        Prompt.stub!(:new).with({'these' => 'params'}).and_return(mock_prompt(:save => false))
        post :create, :prompt => {:these => 'params'}
        assigns[:prompt].should equal(mock_prompt)
      end

      it "re-renders the 'new' template" do
        Prompt.stub!(:new).and_return(mock_prompt(:save => false))
        post :create, :prompt => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested prompt" do
        Prompt.should_receive(:find).with("37").and_return(mock_prompt)
        mock_prompt.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :prompt => {:these => 'params'}
      end

      it "assigns the requested prompt as @prompt" do
        Prompt.stub!(:find).and_return(mock_prompt(:update_attributes => true))
        put :update, :id => "1"
        assigns[:prompt].should equal(mock_prompt)
      end

      it "redirects to the prompt" do
        Prompt.stub!(:find).and_return(mock_prompt(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(prompt_url(mock_prompt))
      end
    end

    describe "with invalid params" do
      it "updates the requested prompt" do
        Prompt.should_receive(:find).with("37").and_return(mock_prompt)
        mock_prompt.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :prompt => {:these => 'params'}
      end

      it "assigns the prompt as @prompt" do
        Prompt.stub!(:find).and_return(mock_prompt(:update_attributes => false))
        put :update, :id => "1"
        assigns[:prompt].should equal(mock_prompt)
      end

      it "re-renders the 'edit' template" do
        Prompt.stub!(:find).and_return(mock_prompt(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested prompt" do
      Prompt.should_receive(:find).with("37").and_return(mock_prompt)
      mock_prompt.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the prompts list" do
      Prompt.stub!(:find).and_return(mock_prompt(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(prompts_url)
    end
  end

end
