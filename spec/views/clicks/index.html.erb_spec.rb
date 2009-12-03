require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/clicks/index.html.erb" do
  include ClicksHelper

  before(:each) do
    assigns[:clicks] = [
      stub_model(Click,
        :site_id => 1,
        :visitor_id => 1,
        :additional_info => "value for additional_info"
      ),
      stub_model(Click,
        :site_id => 1,
        :visitor_id => 1,
        :additional_info => "value for additional_info"
      )
    ]
  end

  it "renders a list of clicks" do
    render
    response.should have_tag("tr>td", 1.to_s, 2)
    response.should have_tag("tr>td", 1.to_s, 2)
    response.should have_tag("tr>td", "value for additional_info".to_s, 2)
  end
end
