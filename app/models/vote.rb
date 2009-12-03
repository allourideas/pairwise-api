class Vote < ActiveRecord::Base
  belongs_to :voteable, :polymorphic => true
  belongs_to :voter, :class_name => "Visitor", :foreign_key => "voter_id"
end
