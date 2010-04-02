require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ChoicesController do
  before(:all) do 

    @aoi_clone = Factory.create(:user, :email => "pius@alum.mit.edu", :password => "password", :password_confirmation => "password", :id => 8)
    @valid_attributes = {
      :site => @aoi_clone,
      :creator => @aoi_clone.default_visitor
      
    }
    @q = Question.create!(@valid_attributes)
  end
  describe "route generation" do
    it "maps #index" do
      route_for(:controller => "choices", :action => "index", :question_id => @q.id.should == "/questions/#{@q.id}/choices"
    end

    it "maps #new" do
      route_for(:controller => "choices", :action => "new", :question_id => @q.id).should == "/questions/#{@q.id}/choices/new"
    end

    it "maps #show" do
      route_for(:controller => "choices", :action => "show", :id => "1", :question_id => @q.id).should == "/questions/#{@q.id}/choices/1"
    end

    it "maps #edit" do
      route_for(:controller => "choices", :action => "edit", :id => "1", :question_id => @q.id).should == "/questions/#{@q.id}/choices/1/edit"
    end

    it "maps #create" do
      route_for(:controller => "choices", :action => "create", :question_id => @q.id).should == {:path => "/questions/#{@q.id}/choices", :method => :post}
    end

    it "maps #update" do
      route_for(:controller => "choices", :action => "update", :id => "1", :question_id => @q.id).should == {:path =>"/questions/#{@q.id}/choices/1", :method => :put}
    end

    it "maps #destroy" do
      route_for(:controller => "choices", :action => "destroy", :id => "1", :question_id => @q.id).should == {:path =>"/questions/#{@q.id}/choices/1", :method => :delete}
    end
  end

  describe "route recognition" do
    it "generates params for #index" do
      params_from(:get, "/questions/#{@q.id}/choices").should == {:controller => "choices", :action => "index", :question_id => @q.id}
    end

    it "generates params for #new" do
      params_from(:get, "/questions/#{@q.id}/choices/new").should == {:controller => "choices", :action => "new", :question_id => @q.id}
    end

    it "generates params for #create" do
      params_from(:post, "/questions/#{@q.id}/choices").should == {:controller => "choices", :action => "create", :question_id => @q.id}
    end

    it "generates params for #show" do
      params_from(:get, "/questions/#{@q.id}/choices/1").should == {:controller => "choices", :action => "show", :id => "1", :question_id => @q.id}
    end

    it "generates params for #edit" do
      params_from(:get, "/questions/#{@q.id}/choices/1/edit").should == {:controller => "choices", :action => "edit", :id => "1", :question_id => @q.id}
    end

    it "generates params for #update" do
      params_from(:put, "/questions/#{@q.id}/choices/1").should == {:controller => "choices", :action => "update", :id => "1", :question_id => @q.id}
    end

    it "generates params for #destroy" do
      params_from(:delete, "/questions/#{@q.id}/choices/1").should == {:controller => "choices", :action => "destroy", :id => "1", :question_id => @q.id}
    end
  end
end
