class Fixnum
  # actionpack-2.3.18/lib/action_controller/assertions/selector_assertions.rb:276
  # attempts to get encoding of Fixnum when doing has_tag "foo", :text => 3
  # Example: bundle exec spec spec/integration/visitors_spec.rb -e "should return the bounces for a single question"
  def encoding
    Encoding::UTF_8
  end
end
