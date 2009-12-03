require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/clicks/new.html.erb" do
  include ClicksHelper

  before(:each) do
    assigns[:click] = stub_model(Click,
      :new_record? => true,
      :site_id => 1,
      :visitor_id => 1,
      :additional_info => "value for additional_info"
    )
  end

  it "renders new click form" do
    render

    response.should have_tag("form[action=?][method=post]", clicks_path) do
      with_tag("input#click_site_id[name=?]", "click[site_id]")
      with_tag("input#click_visitor_id[name=?]", "click[visitor_id]")
      with_tag("textarea#click_additional_info[name=?]", "click[additional_info]")
    end
  end
end
