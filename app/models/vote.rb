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
  belongs_to :choice, :counter_cache => true, :counter_cache => :wins
  belongs_to :loser_choice, :class_name => "Choice", :foreign_key => "loser_choice_id", :counter_cache => :losses
  has_one :appearance, :as => :answerable

  named_scope :recent, lambda { |*args| {:conditions => ["created_at > ?", (args.first || Date.today.beginning_of_day)]} }
  named_scope :with_question, lambda { |*args| {:conditions => {:question_id => args.first }} }
  named_scope :with_voter_ids, lambda { |*args| {:conditions => {:voter_id=> args.first }} }
  named_scope :active, :include => :choice, :conditions => { 'choices.active' => true }
  named_scope :active_loser, :include => :loser_choice, :conditions => { 'choices.active' => true }

  default_scope :conditions => "#{table_name}.valid_record = 1"

  serialize :tracking

  after_create :update_winner_choice, :update_loser_choice
  after_save :update_cached_values_based_on_flags

  def self.find_without_default_scope(*args)
    with_exclusive_scope() do
      find(*args)
    end
  end

  def self.find_each_without_default_scope(*args, &block)
    with_exclusive_scope() do
      find_each(*args, &block)
    end
  end

  def update_winner_choice
    choice.reload              # make sure we're using updated counter values
    choice.compute_score!
  end
  
  def update_loser_choice 
    loser_choice.reload
    loser_choice.compute_score!
  end

  # this is necessary to handle counter cache, at least until the following patch is accepted:
  # https://rails.lighthouseapp.com/projects/8994/tickets/3521-patch-add-conditional-counter-cache
  def update_cached_values_based_on_flags
     if valid_record_changed?
	     if valid_record
		     Question.increment_counter(:votes_count, self.question_id)
		     Prompt.increment_counter(:votes_count, self.prompt_id)
		     Choice.increment_counter(:wins, self.choice_id)
		     Choice.increment_counter(:losses, self.loser_choice_id)
	     else
		     Question.decrement_counter(:votes_count, self.question_id)
		     Prompt.decrement_counter(:votes_count, self.prompt_id)
		     Choice.decrement_counter(:wins, self.choice_id)
		     Choice.decrement_counter(:losses, self.loser_choice_id)
	     end

	     choice.reload
	     choice.compute_score!
	     loser_choice.reload
	     loser_choice.compute_score!
     end
  end

  def to_xml(options={})
    opts = {:except => 'tracking'}
    options.merge!(opts)
    super(options) do |xml|
      xml.tracking do
        self.tracking.each do |key, value|
          xml.tag!(key.to_s) { value }
        end
      end
    end
  end
end
