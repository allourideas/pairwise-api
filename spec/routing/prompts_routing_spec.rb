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
    it "maps #show" do
      route_for(:controller => "prompts", :action => "show", :id => "1", :question_id => @q.id.to_s).should == "/questions/#{@q.id}/prompts/1"
    end

  end

  describe "route recognition" do
    it "generates params for #show" do
      params_from(:get, "/questions/#{@q.id}/prompts/1").should == {:controller => "prompts", :action => "show", :id => "1", :question_id => @q.id.to_s}
    end
  end

end
