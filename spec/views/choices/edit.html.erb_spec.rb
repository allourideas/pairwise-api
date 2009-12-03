require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/choices/edit.html.erb" do
  include ChoicesHelper

  before(:each) do
    assigns[:choice] = @choice = stub_model(Choice,
      :new_record? => false
    )
  end

  it "renders the edit choice form" do
    render

    response.should have_tag("form[action=#{choice_path(@choice)}][method=post]") do
    end
  end
end
