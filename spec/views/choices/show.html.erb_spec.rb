require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/choices/show.html.erb" do
  include ChoicesHelper
  before(:each) do
    assigns[:choice] = @choice = stub_model(Choice)
  end

  it "renders attributes in <p>" do
    render
  end
end
