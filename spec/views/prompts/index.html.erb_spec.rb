require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/prompts/index.html.erb" do
  include PromptsHelper

  before(:each) do
    assigns[:prompts] = [
      stub_model(Prompt),
      stub_model(Prompt)
    ]
  end

  it "renders a list of prompts" do
    render
  end
end
