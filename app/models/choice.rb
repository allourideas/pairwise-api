class Choice < ActiveRecord::Base
  include Activation
  
  belongs_to :question, :counter_cache => true
  belongs_to :item
  belongs_to :creator, :class_name => "Visitor", :foreign_key => "creator_id"
  
  validates_presence_of :creator, :on => :create, :message => "can't be blank"
  validates_presence_of :question, :on => :create, :message => "can't be blank"
  #validates_length_of :item, :maximum => 140
  
  has_many :votes
  has_many :prompts_on_the_left, :class_name => "Prompt", :foreign_key => "left_choice_id"
  has_many :prompts_on_the_right, :class_name => "Prompt", :foreign_key => "right_choice_id"
  named_scope :active, :conditions => { :active => true }
  named_scope :inactive, :conditions => { :active => false}
  
  #attr_accessor :data
  
  def question_name
    question.name
  end
  
  def item_data
    item.data
  end
  
  def lose!
    self.loss_count += 1 rescue (self.loss_count = 1)
    self.score = compute_score
    save!
  end
  
  def wins_plus_losses
    #(prompts_on_the_left.collect(&:votes_count).sum + prompts_on_the_right.collect(&:votes_count).sum)
    #Prompt.sum('votes_count', :conditions => "left_choice_id = #{id} OR right_choice_id = #{id}")
    wins + losses
  end
  
  def losses
    loss_count || 0
  end
  
  def wins
    votes_count || 0
  end
  
  after_create :generate_prompts
  def before_create
    puts "just got inside choice#before_create. is set to active? #{self.active?}"
    unless item
      @item = Item.create!(:creator => creator, :data => data)
      self.item = @item
    end
    unless self.score
      self.score = 50.0
    end
    unless self.active?
      puts "this choice was not specifically set to active, so we are now asking if we should auto-activate"
      self.active = question.should_autoactivate_ideas? ? true : false
      puts "should question autoactivate? #{question.should_autoactivate_ideas?}"
      puts "will this choice be active? #{self.active}"
    end
    return true #so active record will save
  end
  
  def compute_score
    # if wins_plus_losses == 0
    #   return 0
    # else
    #   (wins.to_f / wins_plus_losses ) * 100
    # end
    (wins.to_f+1)/(wins+1+losses+1) * 100
  end
  
  def compute_score!
    self.score = compute_score
    save!
  end

  def user_created
    self.item.creator_id != self.question.creator_id
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

  
  protected

  
  def generate_prompts
    #once a choice is added, we need to generate the new prompts (possible combinations of choices)
    #do this in a new process (via delayed jobs)? Maybe just for uploaded ideas
    previous_choices = (self.question.choices - [self])
    return if previous_choices.empty?
    inserts = []

    timestring = Time.now.to_s(:db) #isn't rails awesome?

    #add prompts with this choice on the left
    previous_choices.each do |r|
	inserts.push("(NULL, #{self.question_id}, NULL, #{self.id}, '#{timestring}', '#{timestring}', NULL, 0, #{r.id}, NULL, NULL)")
    end
    #add prompts with this choice on the right 
    previous_choices.each do |l|
	inserts.push("(NULL, #{self.question_id}, NULL, #{l.id}, '#{timestring}', '#{timestring}', NULL, 0, #{self.id}, NULL, NULL)")
    end
    sql = "INSERT INTO `prompts` (`algorithm_id`, `question_id`, `voter_id`, `left_choice_id`, `created_at`, `updated_at`, `tracking`, `votes_count`, `right_choice_id`, `active`, `randomkey`) VALUES #{inserts.join(', ')}"

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
