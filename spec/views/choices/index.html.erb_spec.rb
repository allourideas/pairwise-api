require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/choices/index.html.erb" do
  include ChoicesHelper

  before(:each) do
    assigns[:choices] = [
      stub_model(Choice),
      stub_model(Choice)
    ]
  end

  it "renders a list of choices" do
    render
  end
end
