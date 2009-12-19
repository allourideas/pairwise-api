class Visitor < ActiveRecord::Base
  belongs_to :site, :class_name => "User", :foreign_key => "site_id"
  has_many :questions, :class_name => "Question", :foreign_key => "creator_id"
  has_many :votes, :class_name => "Vote", :foreign_key => "voter_id"
  has_many :skips, :class_name => "Skip", :foreign_key => "skipper_id"
  has_many :items, :class_name => "Item", :foreign_key => "creator_id"
  has_many :clicks
  
  validates_presence_of :site, :on => :create, :message => "can't be blank"
  validates_uniqueness_of :identifier, :on => :create, :message => "must be unique", :scope => :site_id
  
  def owns?(question)
    questions.include? question
  end
  
  def vote_for!(prompt, ordinality)
    question_vote = votes.create!(:voteable_id => prompt.question_id, :voteable_type => "Question")
    logger.info "Visitor: #{self.inspect} voted for Question: #{prompt.question_id}"
    
    
    choices = prompt.choices
    choice = choices[ordinality] #we need to guarantee that the choices are in the right order (by position)
    prompt_vote = votes.create!(:voteable => prompt)
    logger.info "Visitor: voted for Prompt: #{prompt.id.to_s}"
    # @click = Click.new(:what_was_clicked => "on the API level, inside visitor#vote_for! with prompt id #{prompt.id}, ordinality #{ordinality.to_s}, choice: #{choice.item.data} (id: #{choice.id})")
    # @click.save!
    
    choice_vote = votes.create!(:voteable => choice)
    # logger.info "Visitor: voted for Prompt: #{prompt.id.to_s} for choice #{choice.item.data}"
    # choice.save!
    # choice.score = choice.compute_score
    # logger.info "Just computed the score for that choice and it's apparently #{choice.score}"
    # choice.save!
    #logger.info "Saved. That choice's score is still #{choice.score}"
    other_choices = choices - [choice]
    other_choices.each {|c| c.lose! }
  end
  
  def skip!(prompt)
    prompt_skip = skips.create!(:prompt => prompt)
  end
end
