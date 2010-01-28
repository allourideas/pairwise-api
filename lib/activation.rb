module Activation
  def activate!
    (self.active = true)
    self.save!
  end
  
  def suspend!
    (self.active = false)
    self.save!
  end
  
  def deactivate!
    (self.active = false)
    self.save!
  end
end