require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe QuestionsController do
  describe "route generation" do
    it "maps #index" do
      route_for(:controller => "questions", :action => "index").should == "/questions"
    end

    it "maps #new" do
      route_for(:controller => "questions", :action => "new").should == "/questions/new"
    end

    it "maps #show" do
      route_for(:controller => "questions", :action => "show", :id => "1").should == "/questions/1"
    end

    it "maps #create" do
      route_for(:controller => "questions", :action => "create").should == {:path => "/questions", :method => :post}
    end

    it "maps #update" do
      route_for(:controller => "questions", :action => "update", :id => "1").should == {:path =>"/questions/1", :method => :put}
    end

  end

  describe "route recognition" do
    it "generates params for #index" do
      params_from(:get, "/questions").should == {:controller => "questions", :action => "index"}
    end

    it "generates params for #new" do
      params_from(:get, "/questions/new").should == {:controller => "questions", :action => "new"}
    end

    it "generates params for #create" do
      params_from(:post, "/questions").should == {:controller => "questions", :action => "create"}
    end

    it "generates params for #show" do
      params_from(:get, "/questions/1").should == {:controller => "questions", :action => "show", :id => "1"}
    end

    it "generates params for #update" do
      params_from(:put, "/questions/1").should == {:controller => "questions", :action => "update", :id => "1"}
    end

  end
end
