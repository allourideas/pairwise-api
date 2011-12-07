# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.

  #config.time_zone = 'Eastern Time (US & Canada)'

  config.active_record.default_timezone = 'Eastern Time (US & Canada)'
  config.action_mailer.delivery_method = :smtp
  #config.action_mailer.delivery_method = :sendmail

  config.gem 'hoptoad_notifier',
    :version => '2.4.9'
  config.gem "ambethia-smtp-tls",
    :lib     => "smtp-tls",
    :version => "1.1.2",
    :source  => "http://gems.github.com"
  config.gem "thoughtbot-paperclip",
    :lib     => "paperclip",
    :version => "2.3.1",
    :source  => "http://gems.github.com"
  config.gem "mime-types",
    :lib     => "mime/types",
    :version => "1.16"
  config.gem "xml-simple",
    :lib     => "xmlsimple",
    :version => "1.0.12"
  config.gem "yfactorial-utility_scopes",
    :lib     => "utility_scopes",
    :version => "0.2.2",
    :source  => "http://gems.github.com"
  config.gem "justinfrench-formtastic", 
    :lib     => 'formtastic', 
    :source  => 'http://gems.github.com',
    :version => '0.2.2'
  config.gem "josevalim-inherited_resources", 
    :lib     => 'inherited_resources', 
    :source  => 'http://gems.github.com',
    :version => '0.9.1'
  config.gem "thoughtbot-clearance", 
    :lib     => 'clearance', 
    :source  => 'http://gems.github.com', 
    :version => '0.8.2'
  config.gem "fastercsv",
    :lib     => 'fastercsv',
    :version => '1.5.1'
  config.gem 'delayed_job',
    :version => '2.0.6'
  config.gem 'redis',
    :version => '1.0.7'
  config.gem 'newrelic_rpm',
    :version => '3.3.0'

  config.gem 'sendgrid'
  config.gem 'json'
end

