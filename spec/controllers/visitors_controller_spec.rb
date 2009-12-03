require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe VisitorsController do

  def mock_visitor(stubs={})
    @mock_visitor ||= mock_model(Visitor, stubs)
  end

  describe "GET index" do
    it "assigns all visitors as @visitors" do
      Visitor.stub!(:find).with(:all).and_return([mock_visitor])
      get :index
      assigns[:visitors].should == [mock_visitor]
    end
  end

  describe "GET show" do
    it "assigns the requested visitor as @visitor" do
      Visitor.stub!(:find).with("37").and_return(mock_visitor)
      get :show, :id => "37"
      assigns[:visitor].should equal(mock_visitor)
    end
  end

  describe "GET new" do
    it "assigns a new visitor as @visitor" do
      Visitor.stub!(:new).and_return(mock_visitor)
      get :new
      assigns[:visitor].should equal(mock_visitor)
    end
  end

  describe "GET edit" do
    it "assigns the requested visitor as @visitor" do
      Visitor.stub!(:find).with("37").and_return(mock_visitor)
      get :edit, :id => "37"
      assigns[:visitor].should equal(mock_visitor)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created visitor as @visitor" do
        Visitor.stub!(:new).with({'these' => 'params'}).and_return(mock_visitor(:save => true))
        post :create, :visitor => {:these => 'params'}
        assigns[:visitor].should equal(mock_visitor)
      end

      it "redirects to the created visitor" do
        Visitor.stub!(:new).and_return(mock_visitor(:save => true))
        post :create, :visitor => {}
        response.should redirect_to(visitor_url(mock_visitor))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved visitor as @visitor" do
        Visitor.stub!(:new).with({'these' => 'params'}).and_return(mock_visitor(:save => false))
        post :create, :visitor => {:these => 'params'}
        assigns[:visitor].should equal(mock_visitor)
      end

      it "re-renders the 'new' template" do
        Visitor.stub!(:new).and_return(mock_visitor(:save => false))
        post :create, :visitor => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested visitor" do
        Visitor.should_receive(:find).with("37").and_return(mock_visitor)
        mock_visitor.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :visitor => {:these => 'params'}
      end

      it "assigns the requested visitor as @visitor" do
        Visitor.stub!(:find).and_return(mock_visitor(:update_attributes => true))
        put :update, :id => "1"
        assigns[:visitor].should equal(mock_visitor)
      end

      it "redirects to the visitor" do
        Visitor.stub!(:find).and_return(mock_visitor(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(visitor_url(mock_visitor))
      end
    end

    describe "with invalid params" do
      it "updates the requested visitor" do
        Visitor.should_receive(:find).with("37").and_return(mock_visitor)
        mock_visitor.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :visitor => {:these => 'params'}
      end

      it "assigns the visitor as @visitor" do
        Visitor.stub!(:find).and_return(mock_visitor(:update_attributes => false))
        put :update, :id => "1"
        assigns[:visitor].should equal(mock_visitor)
      end

      it "re-renders the 'edit' template" do
        Visitor.stub!(:find).and_return(mock_visitor(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested visitor" do
      Visitor.should_receive(:find).with("37").and_return(mock_visitor)
      mock_visitor.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the visitors list" do
      Visitor.stub!(:find).and_return(mock_visitor(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(visitors_url)
    end
  end

end
