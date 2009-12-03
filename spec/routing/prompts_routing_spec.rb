require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PromptsController do
  describe "route generation" do
    it "maps #index" do
      route_for(:controller => "prompts", :action => "index").should == "/prompts"
    end

    it "maps #new" do
      route_for(:controller => "prompts", :action => "new").should == "/prompts/new"
    end

    it "maps #show" do
      route_for(:controller => "prompts", :action => "show", :id => "1").should == "/prompts/1"
    end

    it "maps #edit" do
      route_for(:controller => "prompts", :action => "edit", :id => "1").should == "/prompts/1/edit"
    end

    it "maps #create" do
      route_for(:controller => "prompts", :action => "create").should == {:path => "/prompts", :method => :post}
    end

    it "maps #update" do
      route_for(:controller => "prompts", :action => "update", :id => "1").should == {:path =>"/prompts/1", :method => :put}
    end

    it "maps #destroy" do
      route_for(:controller => "prompts", :action => "destroy", :id => "1").should == {:path =>"/prompts/1", :method => :delete}
    end
  end

  describe "route recognition" do
    it "generates params for #index" do
      params_from(:get, "/prompts").should == {:controller => "prompts", :action => "index"}
    end

    it "generates params for #new" do
      params_from(:get, "/prompts/new").should == {:controller => "prompts", :action => "new"}
    end

    it "generates params for #create" do
      params_from(:post, "/prompts").should == {:controller => "prompts", :action => "create"}
    end

    it "generates params for #show" do
      params_from(:get, "/prompts/1").should == {:controller => "prompts", :action => "show", :id => "1"}
    end

    it "generates params for #edit" do
      params_from(:get, "/prompts/1/edit").should == {:controller => "prompts", :action => "edit", :id => "1"}
    end

    it "generates params for #update" do
      params_from(:put, "/prompts/1").should == {:controller => "prompts", :action => "update", :id => "1"}
    end

    it "generates params for #destroy" do
      params_from(:delete, "/prompts/1").should == {:controller => "prompts", :action => "destroy", :id => "1"}
    end
  end
end
