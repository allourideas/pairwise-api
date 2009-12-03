require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/prompts/show.html.erb" do
  include PromptsHelper
  before(:each) do
    assigns[:prompt] = @prompt = stub_model(Prompt)
  end

  it "renders attributes in <p>" do
    render
  end
end
