class Vote < ActiveRecord::Base
#  belongs_to :voteable, :polymorphic => true, :counter_cache => true
  belongs_to :voter, :class_name => "Visitor", :foreign_key => "voter_id"
  belongs_to :question, :counter_cache => true
  belongs_to :prompt, :counter_cache => true
  belongs_to :choice, :counter_cache => true
  belongs_to :loser_choice, :class_name => "Choice", :foreign_key => "loser_choice_id"
end
