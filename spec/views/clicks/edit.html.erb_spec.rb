require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/clicks/edit.html.erb" do
  include ClicksHelper

  before(:each) do
    assigns[:click] = @click = stub_model(Click,
      :new_record? => false,
      :site_id => 1,
      :visitor_id => 1,
      :additional_info => "value for additional_info"
    )
  end

  it "renders the edit click form" do
    render

    response.should have_tag("form[action=#{click_path(@click)}][method=post]") do
      with_tag('input#click_site_id[name=?]', "click[site_id]")
      with_tag('input#click_visitor_id[name=?]', "click[visitor_id]")
      with_tag('textarea#click_additional_info[name=?]', "click[additional_info]")
    end
  end
end
