require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PromptsController do
  before(:all) do 

    @aoi_clone = Factory.create(:user)
    @valid_attributes = {
      :site => @aoi_clone,
      :creator => @aoi_clone.default_visitor
      
    }
    @q = Question.create!(@valid_attributes)
  end

  describe "route generation" do
    it "maps #index" do
      route_for(:controller => "prompts", :action => "index", :question_id => @q.id.to_s).should == "/questions/#{@q.id}/prompts/index"
    end

    it "maps #new" do
      route_for(:controller => "prompts", :action => "new", :question_id => @q.id.to_s).should == "/questions/#{@q.id}/prompts/new"
    end

    it "maps #show" do
      route_for(:controller => "prompts", :action => "show", :id => "1", :question_id => @q.id.to_s).should == "/questions/#{@q.id}/prompts/1"
    end

    it "maps #edit" do
      route_for(:controller => "prompts", :action => "edit", :id => "1", :question_id => @q.id.to_s).should == "/questions/#{@q.id}/prompts/1/edit"
    end

    it "maps #create" do
      route_for(:controller => "prompts", :action => "create", :question_id => @q.id.to_s).should == {:path => "/questions/#{@q.id}/prompts", :method => :post}
    end

    it "maps #update" do
      route_for(:controller => "prompts", :action => "update", :id => "1", :question_id => @q.id.to_s).should == {:path =>"/questions/#{@q.id}/prompts/1", :method => :put}
    end

    it "maps #destroy" do
      route_for(:controller => "prompts", :action => "destroy", :id => "1", :question_id => @q.id.to_s).should == {:path =>"/questions/#{@q.id}/prompts/1", :method => :delete}
    end
  end

  describe "route recognition" do
    it "generates params for #index" do
      params_from(:get, "/questions/#{@q.id}/prompts").should == {:controller => "prompts", :action => "index", :question_id => @q.id.to_s}
    end

    it "generates params for #new" do
      params_from(:get, "/questions/#{@q.id}/prompts/new").should == {:controller => "prompts", :action => "new", :question_id => @q.id.to_s}
    end

    it "generates params for #create" do
      params_from(:post, "/questions/#{@q.id}/prompts").should == {:controller => "prompts", :action => "create", :question_id => @q.id.to_s}
    end

    it "generates params for #show" do
      params_from(:get, "/questions/#{@q.id}/prompts/1").should == {:controller => "prompts", :action => "show", :id => "1", :question_id => @q.id.to_s}
    end

    it "generates params for #edit" do
      params_from(:get, "/questions/#{@q.id}/prompts/1/edit").should == {:controller => "prompts", :action => "edit", :id => "1", :question_id => @q.id.to_s}
    end

    it "generates params for #update" do
      params_from(:put, "/questions/#{@q.id}/prompts/1").should == {:controller => "prompts", :action => "update", :id => "1", :question_id => @q.id.to_s}
    end

    it "generates params for #destroy" do
      params_from(:delete, "/questions/#{@q.id}/prompts/1").should == {:controller => "prompts", :action => "destroy", :id => "1", :question_id => @q.id.to_s}
    end
  end
end
