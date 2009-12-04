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
    logger.info 'testing'
    choices = prompt.choices
    choice = choices[ordinality] #we need to guarantee that the choices are in the right order (by position)
    prompt_vote = votes.create!(:voteable => prompt)
    puts "Visitor: #{self.inspect} voted for Prompt: #{prompt.inspect}"
    choice_vote = votes.create!(:voteable => choice)
    puts "Visitor: #{self.inspect} voted for Choice: #{choice.inspect}"
    choice.save!
    choice.score = choice.compute_score
    puts "Just computed the score for that choice and it's apparently #{choice.score}"
    choice.save!
    puts "Saved. That choice's score is still #{choice.score}"
    other_choices = choices - [choice]
    other_choices.each {|c| c.lose! }
  end
  
  def skip!(prompt)
    prompt_skip = skips.create!(:prompt => prompt)
  end
end
