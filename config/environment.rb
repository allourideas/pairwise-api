# Be sure to restart your server when you modify this file
Encoding.default_external = Encoding.default_internal = Encoding::UTF_8 if defined? Encoding


# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.

  #config.time_zone = 'Eastern Time (US & Canada)'

  config.active_record.default_timezone = :utc
  config.action_mailer.delivery_method = :smtp
  #config.action_mailer.delivery_method = :sendmail
  #
  config.rails_lts_options = { :default => :hardened }
end

