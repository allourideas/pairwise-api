class Visitor < ActiveRecord::Base
  belongs_to :site, :class_name => "User", :foreign_key => "site_id"
  has_many :questions, :class_name => "Question", :foreign_key => "creator_id"
  has_many :votes, :class_name => "Vote", :foreign_key => "voter_id"
  has_many :skips, :class_name => "Skip", :foreign_key => "skipper_id"
  has_many :items, :class_name => "Item", :foreign_key => "creator_id"
  has_many :clicks
  
  validates_presence_of :site, :on => :create, :message => "can't be blank"
# validates_uniqueness_of :identifier, :on => :create, :message => "must be unique", :scope => :site_id

 named_scope :with_tracking, lambda { |*args| {:include => :votes, :conditions => { :identifier => args.first } }}

  def owns?(question)
    questions.include? question
  end
  
  def vote_for!(prompt, ordinality)
    choices = prompt.choices
    choice = choices[ordinality] #we need to guarantee that the choices are in the right order (by position)
    other_choices = choices - [choice]
    other_choices.each do |c| 
	    c.lose!
    end
    
    loser_choice = other_choices.first
    votes.create!(:question_id => prompt.question_id, :prompt_id => prompt.id, :voter_id=> self.id, :choice_id => choice.id, :loser_choice_id => loser_choice.id)
    # Votes count is a cached value, creating the vote above will increment it in the db, but to get the proper score, we need to increment it in the current object
    # The updated votes_count object is not saved to the db, so we don't need to worry about double counting
    # Alternatively, we could just do choice.reload, but that results in another db read
    choice.votes_count +=1
    choice.compute_score! #update score after win
  end
  
  def skip!(prompt)
    prompt_skip = skips.create!(:prompt => prompt)
  end
end
