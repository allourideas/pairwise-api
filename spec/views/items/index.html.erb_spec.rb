require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/items/index.html.erb" do
  include ItemsHelper

  before(:each) do
    assigns[:items] = [
      stub_model(Item),
      stub_model(Item)
    ]
  end

  it "renders a list of items" do
    render
  end
end
