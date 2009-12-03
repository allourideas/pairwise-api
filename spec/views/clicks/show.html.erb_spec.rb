require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/clicks/show.html.erb" do
  include ClicksHelper
  before(:each) do
    assigns[:click] = @click = stub_model(Click,
      :site_id => 1,
      :visitor_id => 1,
      :additional_info => "value for additional_info"
    )
  end

  it "renders attributes in <p>" do
    render
    response.should have_text(/1/)
    response.should have_text(/1/)
    response.should have_text(/value\ for\ additional_info/)
  end
end
