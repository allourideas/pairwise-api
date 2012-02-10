# Settings specified here will take precedence over those in config/environment.rb

# We'd like to stay as close to prod as possible
# Code is not reloaded between requests
config.cache_classes = true

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Disable delivery errors if you bad email addresses should just be ignored
config.action_mailer.raise_delivery_errors = false

# set constants containing sensitive information
# such as passwords for sendgrid, etc.
extra_conf = "/data/extra-conf/environment-variables.rb"
if File.exists?(extra_conf)
  require extra_conf
end
