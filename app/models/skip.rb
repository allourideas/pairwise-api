class Skip < ActiveRecord::Base
  belongs_to :skipper, :class_name => "Visitor", :foreign_key => "skipper_id"
  belongs_to :prompt, :class_name => "Prompt", :foreign_key => "prompt_id"
end
