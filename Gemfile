source :rubygems
source "http://gems.github.com"

gem "rake", "~> 0.9.2.2"
gem "rdoc", "~> 3.12"
gem "rails", "2.3.15"
gem "hoptoad_notifier", "2.4.9"
gem "ambethia-smtp-tls", "1.1.2", :require => "smtp-tls"
gem "paperclip", "2.3.1"
gem "mime-types", "1.16",
    :require => "mime/types"
gem "xml-simple", "1.0.12",
    :require     => "xmlsimple"
gem "yfactorial-utility_scopes", "0.2.2",
    :require     => "utility_scopes"
gem "formtastic", "~> 0.2.2"
gem "inherited_resources",  "1.0.4"
gem "has_scope",  "0.4.2"
gem "responders",  "0.4.8"
gem "thoughtbot-clearance", "0.8.2",
    :require     => "clearance"
gem "fastercsv", "1.5.1"
gem "delayed_job", "2.0.6"
gem "redis", "~> 3.0.1"

gem "sendgrid", "0.1.4"
gem "json_pure", "1.4.6"
gem "rubaidh-google_analytics", "1.1.4", :require => "rubaidh/google_analytics"
gem 'mysql2', '0.2.18'

group :production do
  gem 'ey_config'
end
group :cucumber do
  gem 'cucumber', '1.1.0'
  gem 'cucumber-rails', '0.3.2'
  gem 'webrat', "0.5.3"
  gem 'fakeweb', '1.2.5'
end

group :test do
  gem "rspec", "~>1.3.1"
  gem "rspec-rails", "1.3.4"
  gem "shoulda", "~>2.10.1"
  gem "jtrupiano-timecop", "0.2.1",
    :require     => "timecop"
  gem "fakeweb", "1.2.5"
  gem "jferris-mocha", "0.9.5.0.1241126838",
    :require     => "mocha"
end

group :test, :cucumber do
  gem 'factory_girl', '1.2.3'
  gem 'mock_redis', '0.4.1'
end
gem "newrelic_rpm"
