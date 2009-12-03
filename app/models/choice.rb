class Choice < ActiveRecord::Base
  belongs_to :question
  belongs_to :item
  belongs_to :creator, :class_name => "Visitor", :foreign_key => "creator_id"
  validates_presence_of :creator, :on => :create, :message => "can't be blank"
  validates_presence_of :question, :on => :create, :message => "can't be blank"
  has_many :votes, :as => :voteable 
  
  attr_accessor :data
  
  
  after_create :generate_prompts
  def before_create
    @item = Item.create!(:creator => creator, :data => data)
    self.item = @item
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
