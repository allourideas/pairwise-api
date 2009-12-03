require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/prompts/edit.html.erb" do
  include PromptsHelper

  before(:each) do
    assigns[:prompt] = @prompt = stub_model(Prompt,
      :new_record? => false
    )
  end

  it "renders the edit prompt form" do
    render

    response.should have_tag("form[action=#{prompt_path(@prompt)}][method=post]") do
    end
  end
end
