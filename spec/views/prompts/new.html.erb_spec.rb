require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/prompts/new.html.erb" do
  include PromptsHelper

  before(:each) do
    assigns[:prompt] = stub_model(Prompt,
      :new_record? => true
    )
  end

  it "renders new prompt form" do
    render

    response.should have_tag("form[action=?][method=post]", prompts_path) do
    end
  end
end
