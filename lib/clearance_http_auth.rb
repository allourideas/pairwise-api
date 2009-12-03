#http://gist.github.com/159604

# Overload Clearance's `deny_access` methods to allow authentication with HTTP-Auth for eg. API access
# Modeled after technoweenie's restful_authentication
# http://github.com/technoweenie/restful-authentication/blob/7235d9150e8beb80a819923a4c871ef4069c6759/generators/authenticated/templates/authenticated_system.rb#L74-76
#
# In lib/clearance_http_auth.rb

module Clearance
  module Authentication
 
    module InstanceMethods
      
      def deny_access(flash_message = nil, opts = {})
        store_location
        flash[:failure] = flash_message if flash_message
        respond_to do |format|
          format.html { redirect_to new_session_url }
          format.any(:json, :xml) do
            authenticate_or_request_with_http_basic('Pairwise API') do |login, password|
              @_current_user = ::User.authenticate(login, password)
            end
          end
        end
      end
 
    end
 
  end
end