class Vote < ActiveRecord::Base
#  belongs_to :voteable, :polymorphic => true, :counter_cache => true
  validates_presence_of :question
  validates_presence_of :prompt
  validates_presence_of :choice
  validates_presence_of :loser_choice
  validates_presence_of :voter

  belongs_to :voter, :class_name => "Visitor", :foreign_key => "voter_id"
  belongs_to :question, :counter_cache => true
  belongs_to :prompt, :counter_cache => true
  belongs_to :choice, :counter_cache => true
  belongs_to :loser_choice, :class_name => "Choice", :foreign_key => "loser_choice_id"
  belongs_to :appearance

  named_scope :recent, lambda { |*args| {:conditions => ["created_at > ?", (args.first || Date.today.beginning_of_day)]} }
  named_scope :with_question, lambda { |*args| {:conditions => {:question_id => args.first }} }
  named_scope :with_voter_ids, lambda { |*args| {:conditions => {:voter_id=> args.first }} }
  named_scope :active, :include => :choice, :conditions => { 'choices.active' => true }

  after_create :update_winner_choice, :update_loser_choice

  def update_winner_choice
     choice.win!
  end
  
  def update_loser_choice 
     loser_choice.lose!
  end
end
