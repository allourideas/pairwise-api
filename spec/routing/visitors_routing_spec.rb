require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe VisitorsController do
  describe "route generation" do
    it "maps #index" do
      route_for(:controller => "visitors", :action => "index").should == "/visitors"
    end

    it "maps #new" do
      route_for(:controller => "visitors", :action => "new").should == "/visitors/new"
    end

    it "maps #show" do
      route_for(:controller => "visitors", :action => "show", :id => "1").should == "/visitors/1"
    end

    it "maps #edit" do
      route_for(:controller => "visitors", :action => "edit", :id => "1").should == "/visitors/1/edit"
    end

    it "maps #create" do
      route_for(:controller => "visitors", :action => "create").should == {:path => "/visitors", :method => :post}
    end

    it "maps #update" do
      route_for(:controller => "visitors", :action => "update", :id => "1").should == {:path =>"/visitors/1", :method => :put}
    end

    it "maps #destroy" do
      route_for(:controller => "visitors", :action => "destroy", :id => "1").should == {:path =>"/visitors/1", :method => :delete}
    end
  end

  describe "route recognition" do
    it "generates params for #index" do
      params_from(:get, "/visitors").should == {:controller => "visitors", :action => "index"}
    end

    it "generates params for #new" do
      params_from(:get, "/visitors/new").should == {:controller => "visitors", :action => "new"}
    end

    it "generates params for #create" do
      params_from(:post, "/visitors").should == {:controller => "visitors", :action => "create"}
    end

    it "generates params for #show" do
      params_from(:get, "/visitors/1").should == {:controller => "visitors", :action => "show", :id => "1"}
    end

    it "generates params for #edit" do
      params_from(:get, "/visitors/1/edit").should == {:controller => "visitors", :action => "edit", :id => "1"}
    end

    it "generates params for #update" do
      params_from(:put, "/visitors/1").should == {:controller => "visitors", :action => "update", :id => "1"}
    end

    it "generates params for #destroy" do
      params_from(:delete, "/visitors/1").should == {:controller => "visitors", :action => "destroy", :id => "1"}
    end
  end
end
