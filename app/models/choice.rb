class Choice < ActiveRecord::Base
  belongs_to :question
  belongs_to :item
  belongs_to :creator, :class_name => "Visitor", :foreign_key => "creator_id"
  
  validates_presence_of :creator, :on => :create, :message => "can't be blank"
  validates_presence_of :question, :on => :create, :message => "can't be blank"
  
  has_many :votes, :as => :voteable 
  has_many :prompts_on_the_left, :class_name => "Prompt", :foreign_key => "left_choice_id"
  has_many :prompts_on_the_right, :class_name => "Prompt", :foreign_key => "right_choice_id"
  
  attr_accessor :data
  
  def item_data
    item.data
  end
  
  def lose!
    self.loss_count += 1 rescue (self.loss_count = 1)
    save!
  end
  
  def wins_plus_losses
    #(prompts_on_the_left.collect(&:votes_count).sum + prompts_on_the_right.collect(&:votes_count).sum)
    Prompt.sum('votes_count', :conditions => "left_choice_id = #{id} OR right_choice_id = #{id}")
    #wins + losses
  end
  
  def losses
    loss_count
  end
  
  def wins
    votes_count
  end
  
  after_create :generate_prompts
  def before_create
    unless item
      @item = Item.create!(:creator => creator, :data => data)
      self.item = @item
    end
    unless self.score
      self.score = 0.0
    end
    return true #so active record will save
  end
  
  def compute_score
    if wins_plus_losses == 0
      return 0
    else
      (wins.to_f / wins_plus_losses ) * 100
    end
  end
  
  protected

  
  def generate_prompts
    #once a choice is added, we need to generate the new prompts (possible combinations of choices)
    #do this in a new process (via delayed jobs)
    previous_choices = (self.question.choices - [self])
    return if previous_choices.empty?
    for c in previous_choices
      question.prompts.create!(:left_choice => c, :right_choice => self)
      question.prompts.create!(:left_choice => self, :right_choice => c)
    end
  end
end
