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

    if options.delete(:skip_fraud_protection)
       last_answered_appearance = self.appearances.find(:first,
			:conditions => ["appearances. question_id = ? AND appearances.answerable_id IS NOT NULL", prompt.question_id],
			:order => 'id DESC')
       if last_answered_appearance && last_answered_appearance.answerable_type == "Skip"
              options.merge!(:valid_record => false)
              options.merge!(:validity_information => "Fraud protection: last visitor action was a skip")
       end
    end

    if options.delete(:force_invalid_vote)
      options.merge!(:valid_record => false)
      options.merge!(:validity_information => "API call forced invalid vote")
    end

    associate_appearance = false
    if options[:appearance_lookup] 
       @appearance = prompt.appearances.find_by_lookup(options.delete(:appearance_lookup))
       return nil unless @appearance # don't allow people to fake appearance lookups
      associate_appearance = true
    end
    
    choice = prompt.choices[ordinality] #we need to guarantee that the choices are in the right order (by position)
    other_choices = prompt.choices - [choice]
    loser_choice = other_choices.first
    
    options.merge!(:question_id => prompt.question_id, :prompt => prompt, :voter => self, :choice => choice, :loser_choice => loser_choice) 

    v = votes.create!(options)
    safely_associate_appearance(v, @appearance) if associate_appearance
    v
  end

  def skip!(options)
    return nil if !options || !options[:prompt]

    prompt = options.delete(:prompt)

    associate_appearance = false
    if options[:appearance_lookup]
      @appearance = prompt.appearances.find_by_lookup(options.delete(:appearance_lookup))
      return nil unless @appearance
      associate_appearance = true
    end

    if options.delete(:force_invalid_vote)
      options.merge!(:valid_record => false)
      options.merge!(:validity_information => "API call forced invalid vote")
    end

    options.merge!(:question_id => prompt.question_id, :prompt_id => prompt.id, :skipper_id => self.id)
    prompt_skip = skips.create!(options)
    if associate_appearance
      safely_associate_appearance(prompt_skip, @appearance)
    end
    prompt_skip
  end

  # Safely associates appearance with object, but making sure no other object
  # is already associated with this appearance. object is either vote or skip.
  def safely_associate_appearance(object, appearance)
    appearance = expired_session_mismatch_fix(object, appearance)
    # Manually update Appearance with id to ensure no double votes for a
    # single appearance.  Only update the answerable_id if it is NULL.
    # If we can't find any rows to update, then this object should be invalid.
    rows_updated = Appearance.update_all("answerable_id = #{object.id}, answerable_type = '#{object.class.to_s}', updated_at = '#{Time.now.utc.to_s(:db)}'", "id = #{appearance.id} AND answerable_id IS NULL")
    if rows_updated != 1
      object.update_attributes!(:valid_record => false, :validity_information => "Appearance #{appearance.id} already answered")
    end
  end

  # if the voter_id / skipper_id for the object and appearance don't match
  # and vote.created_at > 10 minutes after appearance.created_at, which indicates
  # a session expiration, then return a new copy of the appearance
  # object may be Vote or Skip
  def expired_session_mismatch_fix(object, appearance)
    obj_voter_id = (object.class == Skip) ? object.skipper_id : object.voter_id
    if obj_voter_id == appearance.voter_id || object.created_at - appearance.created_at < 10 * 60 || !appearance.answerable.nil?
      return appearance
    end
    new_appearance = appearance.clone
    new_appearance.voter_id = obj_voter_id
    new_appearance.answerable_id = nil
    new_appearance.answerable_type = nil
    new_appearance.save
    return new_appearance
  end
end
