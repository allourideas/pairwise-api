class Visitor < ActiveRecord::Base
  belongs_to :site, :class_name => "User", :foreign_key => "site_id"
  has_many :questions, :class_name => "Question", :foreign_key => "creator_id"
  has_many :votes, :class_name => "Vote", :foreign_key => "voter_id"
  has_many :skips, :class_name => "Skip", :foreign_key => "skipper_id"
  has_many :choices, :class_name => "Choice", :foreign_key => "creator_id"
  has_many :clicks
  has_many :appearances, :foreign_key => "voter_id"
  
  validates_presence_of :site, :on => :create, :message => "can't be blank"
# validates_uniqueness_of :identifier, :on => :create, :message => "must be unique", :scope => :site_id

 named_scope :with_tracking, lambda { |*args| {:include => :votes, :conditions => { :identifier => args.first } }}

  def owns?(question)
    questions.include? question
  end
  
  def vote_for!(options)
    return nil if !options || !options[:prompt] || !options[:direction]
    
    prompt = options.delete(:prompt)
    ordinality = (options.delete(:direction) == "left") ? 0 : 1
    
    if options[:appearance_lookup] 
       @appearance = prompt.appearances.find_by_lookup(options.delete(:appearance_lookup))
       return nil unless @appearance # don't allow people to fake appearance lookups
       options.merge!(:appearance_id => @appearance.id)
    end
    
    choice = prompt.choices[ordinality] #we need to guarantee that the choices are in the right order (by position)
    other_choices = prompt.choices - [choice]
    loser_choice = other_choices.first
    
    options.merge!(:question_id => prompt.question_id, :prompt_id => prompt.id, :voter_id=> self.id, :choice_id => choice.id, :loser_choice_id => loser_choice.id) 

    v = votes.create!(options)
  end
  
  def skip!(appearance_lookup, prompt, time_viewed, options = {})
    @a = Appearance.find_by_lookup(appearance_lookup)
    
    skip_create_options  = { :question_id => prompt.question_id, :prompt_id => prompt.id, :skipper_id=> self.id, :time_viewed => time_viewed, :appearance_id => @a.id} 

    #the most common optional reason is 'skip_reason', probably want to refactor to make time viewed an optional parameter
    prompt_skip = skips.create!(skip_create_options.merge(options))

  end
end
