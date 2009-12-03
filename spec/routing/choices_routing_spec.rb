require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ChoicesController do
  describe "route generation" do
    it "maps #index" do
      route_for(:controller => "choices", :action => "index").should == "/choices"
    end

    it "maps #new" do
      route_for(:controller => "choices", :action => "new").should == "/choices/new"
    end

    it "maps #show" do
      route_for(:controller => "choices", :action => "show", :id => "1").should == "/choices/1"
    end

    it "maps #edit" do
      route_for(:controller => "choices", :action => "edit", :id => "1").should == "/choices/1/edit"
    end

    it "maps #create" do
      route_for(:controller => "choices", :action => "create").should == {:path => "/choices", :method => :post}
    end

    it "maps #update" do
      route_for(:controller => "choices", :action => "update", :id => "1").should == {:path =>"/choices/1", :method => :put}
    end

    it "maps #destroy" do
      route_for(:controller => "choices", :action => "destroy", :id => "1").should == {:path =>"/choices/1", :method => :delete}
    end
  end

  describe "route recognition" do
    it "generates params for #index" do
      params_from(:get, "/choices").should == {:controller => "choices", :action => "index"}
    end

    it "generates params for #new" do
      params_from(:get, "/choices/new").should == {:controller => "choices", :action => "new"}
    end

    it "generates params for #create" do
      params_from(:post, "/choices").should == {:controller => "choices", :action => "create"}
    end

    it "generates params for #show" do
      params_from(:get, "/choices/1").should == {:controller => "choices", :action => "show", :id => "1"}
    end

    it "generates params for #edit" do
      params_from(:get, "/choices/1/edit").should == {:controller => "choices", :action => "edit", :id => "1"}
    end

    it "generates params for #update" do
      params_from(:put, "/choices/1").should == {:controller => "choices", :action => "update", :id => "1"}
    end

    it "generates params for #destroy" do
      params_from(:delete, "/choices/1").should == {:controller => "choices", :action => "destroy", :id => "1"}
    end
  end
end
