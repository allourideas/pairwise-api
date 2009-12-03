require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/visitors/show.html.erb" do
  include VisitorsHelper
  before(:each) do
    assigns[:visitor] = @visitor = stub_model(Visitor,
      :site_id => 1,
      :identifier => "value for identifier",
      :tracking => "value for tracking"
    )
  end

  it "renders attributes in <p>" do
    render
    response.should have_text(/1/)
    response.should have_text(/value\ for\ identifier/)
    response.should have_text(/value\ for\ tracking/)
  end
end
