class Export < ActiveRecord::Base
  belongs_to :question
  def self.memory_safe_destroy(id)
    e = self.find(id, :select => :id)
    e.destroy
  end
end
