module IntegrationSupport

  # todo: make automatically included in integration tests
  Spec::Runner.configure do |config|
    config.before(:each, :type => :integration) do
      @api_user = Factory(:email_confirmed_user)
    end
  end

  def get_auth(path, parameters = {}, headers = {})
    auth_wrap(:get, path, parameters, headers)
  end

  def put_auth(path, parameters = {}, headers = {})
    auth_wrap(:put, path, parameters, headers)
  end

  def post_auth(path, parameters = {}, headers = {} )
    auth_wrap(:post, path, parameters, headers)
  end

  def delete_auth(path, parameters = {}, headers = {})
    auth_wrap(:delete, path, parameters, headers)
  end

  def head_auth(path, parameters = {}, headers = {})
    auth_wrap(:head, path, parameters, headers)
  end

  private
  def auth_wrap(method, path, parameters, headers)
    return nil unless [:get, :put, :post, :delete, :head].include? method
    
    auth = ActionController::HttpAuthentication::Basic.encode_credentials(@api_user.email, @api_user.password)
    headers.merge!(:authorization => auth)
    # headers.merge!(:content_type => "application/xml", :authorization => auth)
    # parameters.merge!(:format => 'xml')

    send(method, path, parameters, headers)
  end
end
    
