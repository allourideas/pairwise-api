# Ruby 1.8 String does not have force_encoding method
# Add it to do nothing if it doesn't exist.
if ! "".methods.include? :force_encoding
class String
  def force_encoding(enc)
    self
  end
end
end
