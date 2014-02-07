class Choice < ActiveRecord::Base
  acts_as_versioned :if_changed => [:data, :creator_id, :question_id, :active]

  belongs_to :question, :counter_cache => true
  belongs_to :creator, :class_name => "Visitor", :foreign_key => "creator_id"

  validates_presence_of :creator, :on => :create, :message => "can't be blank"
  validates_presence_of :question, :on => :create, :message => "can't be blank"
  validates_presence_of :data
  #validates_length_of :item, :maximum => 140

  has_many :votes
  has_many :losing_votes, :class_name => "Vote", :foreign_key => "loser_choice_id"
  has_many :flags
  has_many :prompts_on_the_left, :class_name => "Prompt", :foreign_key => "left_choice_id"
  has_many :prompts_on_the_right, :class_name => "Prompt", :foreign_key => "right_choice_id"


  has_many :appearances_on_the_left, :through => :prompts_on_the_left, :source => :appearances
  has_many :appearances_on_the_right, :through => :prompts_on_the_right, :source => :appearances
  has_many :skips_on_the_left, :through => :prompts_on_the_left, :source => :skips
  has_many :skips_on_the_right, :through => :prompts_on_the_right, :source => :skips
  named_scope :active, :conditions => { :active => true }
  named_scope :inactive, :conditions => { :active => false}
  named_scope :not_created_by, lambda { |creator_id|
    { :conditions => ["creator_id <> ?", creator_id] }
  }

  after_save :update_questions_counter
  after_save :update_prompt_queue

  attr_protected :prompts_count, :wins, :losses, :score, :prompts_on_the_right_count, :prompts_on_the_left_count
  attr_readonly :question_id
  attr_accessor :part_of_batch_create

  def update_questions_counter
    unless part_of_batch_create
      self.question.update_attribute(:inactive_choices_count, self.question.choices.inactive.length)
    end
  end

  # if changing a choice to active, we want to regenerate prompts
  def update_prompt_queue
    unless part_of_batch_create
      if self.changed.include?('active') && self.active?
        self.question.mark_prompt_queue_for_refill
        if self.question.choices.size - self.question.inactive_choices_count > 1 && self.question.uses_catchup?
          self.question.delay.add_prompt_to_queue
        end
      end
    end
  end

  def before_create
    unless self.score
      self.score = 50.0
    end
    unless self.active?
     #puts "this choice was not specifically set to active, so we are now asking if we should auto-activate"
      self.active = question.should_autoactivate_ideas? ? true : false
      #puts "should question autoactivate? #{question.should_autoactivate_ideas?}"
      #puts "will this choice be active? #{self.active}"
    end
    return true #so active record will save
  end

  def compute_score
    (wins.to_f+1)/(wins+1+losses+1) * 100
  end

  def compute_score!
    self.score = compute_score
    #changed to quote tables according the database type (wasn't working in postgres)
    Choice.connection.execute("UPDATE #{connection.quote_table_name("choices")}
      SET #{connection.quote_column_name("score")} = #{self.score},
        #{connection.quote_column_name("updated_at")} = '#{Time.now.utc.to_s(:db)}'
      WHERE
        #{connection.quote_column_name("id")} = #{self.id}")
  end

  def user_created
    self.creator_id != self.question.creator_id
  end

  def compute_bt_score(btprobs = nil)
      if btprobs.nil?
	      btprobs = self.question.bradley_terry_probs
      end

      p_i = btprobs[self.id]

      total = 0
      btprobs.each do |id, p_j|
	      if id == self.id
		      next
	      end

	      total += (p_i / (p_i + p_j))
      end

      total / (btprobs.size-1)

  end

  def activate!
    (self.active = true)
    self.save!
  end

  def deactivate!
    (self.active = false)
    self.save!
  end

  protected


  def generate_prompts
    #once a choice is added, we need to generate the new prompts (possible combinations of choices)
    #do this in a new process (via delayed jobs)? Maybe just for uploaded ideas
    previous_choices = (self.question.choices - [self])
    return if previous_choices.empty?
    inserts = []

    timestring = Time.now.utc.to_s(:db) #isn't rails awesome?

    #add prompts with this choice on the left
    previous_choices.each do |r|
	inserts.push("(NULL, #{self.question_id}, NULL, #{self.id}, '#{timestring}', '#{timestring}', NULL, 0, #{r.id}, NULL, NULL)")
    end
    #add prompts with this choice on the right
    previous_choices.each do |l|
	inserts.push("(NULL, #{self.question_id}, NULL, #{l.id}, '#{timestring}', '#{timestring}', NULL, 0, #{self.id}, NULL, NULL)")
    end
    #changed to quote tables according the database type (wasn't working in postgres)
    sql = "INSERT INTO #{connection.quote_table_name("prompts")}
    (#{connection.quote_column_name("algorithm_id")},
    #{connection.quote_column_name("question_id")},
    #{connection.quote_column_name("voter_id")},
    #{connection.quote_column_name("left_choice_id")},
    #{connection.quote_column_name("created_at")},
    #{connection.quote_column_name("updated_at")},
    #{connection.quote_column_name("tracking")},
    #{connection.quote_column_name("votes_count")},
    #{connection.quote_column_name("right_choice_id")},
    #{connection.quote_column_name("active")},
    #{connection.quote_column_name("randomkey")}) VALUES #{inserts.join(', ')}"

    Question.update_counters(self.question_id, :prompts_count => 2*previous_choices.size)


    ActiveRecord::Base.connection.execute(sql)

#VALUES (NULL, 108, NULL, 1892, '2010-03-16 11:12:37', '2010-03-16 11:12:37', NULL, 0, 1893, NULL, NULL)
#    INSERT INTO `prompts` (`algorithm_id`, `question_id`, `voter_id`, `left_choice_id`, `created_at`, `updated_at`, `tracking`, `votes_count`, `right_choice_id`, `active`, `randomkey`) VALUES(NULL, 108, NULL, 1892, '2010-03-16 11:12:37', '2010-03-16 11:12:37', NULL, 0, 1893, NULL, NULL)
    #previous_choices.each { |c|
    #  question.prompts.create!(:left_choice => c, :right_choice => self)
    #  question.prompts.create!(:left_choice => self, :right_choice => c)
    #}
  end
end

