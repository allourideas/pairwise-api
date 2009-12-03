require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/visitors/edit.html.erb" do
  include VisitorsHelper

  before(:each) do
    assigns[:visitor] = @visitor = stub_model(Visitor,
      :new_record? => false,
      :site_id => 1,
      :identifier => "value for identifier",
      :tracking => "value for tracking"
    )
  end

  it "renders the edit visitor form" do
    render

    response.should have_tag("form[action=#{visitor_path(@visitor)}][method=post]") do
      with_tag('input#visitor_site_id[name=?]', "visitor[site_id]")
      with_tag('input#visitor_identifier[name=?]', "visitor[identifier]")
      with_tag('textarea#visitor_tracking[name=?]', "visitor[tracking]")
    end
  end
end
