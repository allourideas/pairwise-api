require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/choices/new.html.erb" do
  include ChoicesHelper

  before(:each) do
    assigns[:choice] = stub_model(Choice,
      :new_record? => true
    )
  end

  it "renders new choice form" do
    render

    response.should have_tag("form[action=?][method=post]", choices_path) do
    end
  end
end
