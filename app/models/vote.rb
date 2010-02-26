class Vote < ActiveRecord::Base
#  belongs_to :voteable, :polymorphic => true, :counter_cache => true
  belongs_to :voter, :class_name => "Visitor", :foreign_key => "voter_id"
  belongs_to :question, :counter_cache => true
  belongs_to :prompt, :counter_cache => true
  belongs_to :choice, :counter_cache => true
  belongs_to :loser_choice, :class_name => "Choice", :foreign_key => "loser_choice_id"

  named_scope :recent, lambda { |*args| {:conditions => ["created_at > ?", (args.first || Date.today.beginning_of_day)]} }
  named_scope :with_question, lambda { |*args| {:conditions => {:question_id => args.first }} }
  named_scope :with_voter_ids, lambda { |*args| {:conditions => {:voter_id=> args.first }} }
end
