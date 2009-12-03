require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ClicksController do
  describe "route generation" do
    it "maps #index" do
      route_for(:controller => "clicks", :action => "index").should == "/clicks"
    end

    it "maps #new" do
      route_for(:controller => "clicks", :action => "new").should == "/clicks/new"
    end

    it "maps #show" do
      route_for(:controller => "clicks", :action => "show", :id => "1").should == "/clicks/1"
    end

    it "maps #edit" do
      route_for(:controller => "clicks", :action => "edit", :id => "1").should == "/clicks/1/edit"
    end

    it "maps #create" do
      route_for(:controller => "clicks", :action => "create").should == {:path => "/clicks", :method => :post}
    end

    it "maps #update" do
      route_for(:controller => "clicks", :action => "update", :id => "1").should == {:path =>"/clicks/1", :method => :put}
    end

    it "maps #destroy" do
      route_for(:controller => "clicks", :action => "destroy", :id => "1").should == {:path =>"/clicks/1", :method => :delete}
    end
  end

  describe "route recognition" do
    it "generates params for #index" do
      params_from(:get, "/clicks").should == {:controller => "clicks", :action => "index"}
    end

    it "generates params for #new" do
      params_from(:get, "/clicks/new").should == {:controller => "clicks", :action => "new"}
    end

    it "generates params for #create" do
      params_from(:post, "/clicks").should == {:controller => "clicks", :action => "create"}
    end

    it "generates params for #show" do
      params_from(:get, "/clicks/1").should == {:controller => "clicks", :action => "show", :id => "1"}
    end

    it "generates params for #edit" do
      params_from(:get, "/clicks/1/edit").should == {:controller => "clicks", :action => "edit", :id => "1"}
    end

    it "generates params for #update" do
      params_from(:put, "/clicks/1").should == {:controller => "clicks", :action => "update", :id => "1"}
    end

    it "generates params for #destroy" do
      params_from(:delete, "/clicks/1").should == {:controller => "clicks", :action => "destroy", :id => "1"}
    end
  end
end
