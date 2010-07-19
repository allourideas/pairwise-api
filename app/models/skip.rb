class Skip < ActiveRecord::Base
  belongs_to :skipper, :class_name => "Visitor", :foreign_key => "skipper_id"
  belongs_to :question
  belongs_to :prompt
  has_one :appearance, :as => :answerable

  default_scope :conditions => {:valid_record => true}
end
