module IntegrationSupport

  @@default_user = nil

  # todo: make automatically included in integration tests
  Spec::Runner.configure do |config|
    config.before(:each, :type => :integration) do
      # compatibility with old tests using @api_user, remove this
      @api_user = self.default_user = Factory(:email_confirmed_user)
    end
  end

  def default_user=(user)
    @api_user = @@default_user = user
  end

  # generate _auth variation of get/put/post, etc. to automatically
  # send requests with the authentication and accept headers set
  %w(get put post delete head).each do |method|
    define_method(method + "_auth") do |*args|
      if args[0].is_a? User
        user, path, parameters, headers, *ignored  = *args
      else
        path, parameters, headers, *ignored = *args
      end

      user ||= @@default_user
      raise ArgumentError, "No user provided and default user not set" unless user

      auth = ActionController::HttpAuthentication::
        Basic.encode_credentials(user.email, user.password)
      (headers ||= {}).merge!( :authorization => auth,
                               :accept => "application/xml" )

      send(method, path, parameters, headers)
    end
  end

  # need a way to easily fetch content of a Tag
  class HTML::Tag
    def content(tag)
      n = self.find(:tag => tag) or return nil
      n.children.each{ |c| return c.content if c.is_a? HTML::Text }
      nil
    end
  end


  # have_tag doesn't let you iterate over individual nodes like
  # assert_select does for some reason, and using css matchers
  # to do this is ugly.  Time for a patch!
  class Spec::Rails::Matchers::AssertSelect
    def doc_from_with_node(node)
      return node if node.is_a? HTML::Node
      doc_from_without_node(node)
    end

    alias_method_chain :doc_from, :node
  end
  
    
end
    
