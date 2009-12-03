require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ItemsController do
  describe "route generation" do
    it "maps #index" do
      route_for(:controller => "items", :action => "index").should == "/items"
    end

    it "maps #new" do
      route_for(:controller => "items", :action => "new").should == "/items/new"
    end

    it "maps #show" do
      route_for(:controller => "items", :action => "show", :id => "1").should == "/items/1"
    end

    it "maps #edit" do
      route_for(:controller => "items", :action => "edit", :id => "1").should == "/items/1/edit"
    end

    it "maps #create" do
      route_for(:controller => "items", :action => "create").should == {:path => "/items", :method => :post}
    end

    it "maps #update" do
      route_for(:controller => "items", :action => "update", :id => "1").should == {:path =>"/items/1", :method => :put}
    end

    it "maps #destroy" do
      route_for(:controller => "items", :action => "destroy", :id => "1").should == {:path =>"/items/1", :method => :delete}
    end
  end

  describe "route recognition" do
    it "generates params for #index" do
      params_from(:get, "/items").should == {:controller => "items", :action => "index"}
    end

    it "generates params for #new" do
      params_from(:get, "/items/new").should == {:controller => "items", :action => "new"}
    end

    it "generates params for #create" do
      params_from(:post, "/items").should == {:controller => "items", :action => "create"}
    end

    it "generates params for #show" do
      params_from(:get, "/items/1").should == {:controller => "items", :action => "show", :id => "1"}
    end

    it "generates params for #edit" do
      params_from(:get, "/items/1/edit").should == {:controller => "items", :action => "edit", :id => "1"}
    end

    it "generates params for #update" do
      params_from(:put, "/items/1").should == {:controller => "items", :action => "update", :id => "1"}
    end

    it "generates params for #destroy" do
      params_from(:delete, "/items/1").should == {:controller => "items", :action => "destroy", :id => "1"}
    end
  end
end
