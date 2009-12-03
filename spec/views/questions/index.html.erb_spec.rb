require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/questions/index.html.erb" do
  include QuestionsHelper

  before(:each) do
    assigns[:questions] = [
      stub_model(Question),
      stub_model(Question)
    ]
  end

  it "renders a list of questions" do
    render
  end
end
