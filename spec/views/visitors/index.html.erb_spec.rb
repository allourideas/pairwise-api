require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/visitors/index.html.erb" do
  include VisitorsHelper

  before(:each) do
    assigns[:visitors] = [
      stub_model(Visitor,
        :site_id => 1,
        :identifier => "value for identifier",
        :tracking => "value for tracking"
      ),
      stub_model(Visitor,
        :site_id => 1,
        :identifier => "value for identifier",
        :tracking => "value for tracking"
      )
    ]
  end

  it "renders a list of visitors" do
    render
    response.should have_tag("tr>td", 1.to_s, 2)
    response.should have_tag("tr>td", "value for identifier".to_s, 2)
    response.should have_tag("tr>td", "value for tracking".to_s, 2)
  end
end
