class Fixnum
  # actionpack-2.3.18/lib/action_controller/assertions/selector_assertions.rb:276
  # attempts to get encoding of Fixnum when doing has_tag "foo", :text => 3
  def encoding
    Encoding::UTF_8
  end
end
