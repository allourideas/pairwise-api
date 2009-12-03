require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/visitors/new.html.erb" do
  include VisitorsHelper

  before(:each) do
    assigns[:visitor] = stub_model(Visitor,
      :new_record? => true,
      :site_id => 1,
      :identifier => "value for identifier",
      :tracking => "value for tracking"
    )
  end

  it "renders new visitor form" do
    render

    response.should have_tag("form[action=?][method=post]", visitors_path) do
      with_tag("input#visitor_site_id[name=?]", "visitor[site_id]")
      with_tag("input#visitor_identifier[name=?]", "visitor[identifier]")
      with_tag("textarea#visitor_tracking[name=?]", "visitor[tracking]")
    end
  end
end
