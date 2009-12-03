class Question < ActiveRecord::Base
  belongs_to :creator, :class_name => "Visitor", :foreign_key => "creator_id"
  belongs_to :site, :class_name => "User", :foreign_key => "site_id"
  
  has_many :choices
  has_many :prompts do
    def pick(algorithm = nil)
      if algorithm
        algorithm.pick_from(self) #todo
      else
        lambda {prompts[rand(prompts.size-1)]}.call
      end
    end
  end
  after_save :ensure_at_least_two_choices
  
  validates_presence_of :site, :on => :create, :message => "can't be blank"
  validates_presence_of :creator, :on => :create, :message => "can't be blank"
  
  def ensure_at_least_two_choices
    if self.choices.empty?
      ["sample choice 1", "sample choice 2"].each { |choice_text|
        item = Item.create!({:data => choice_text, :creator => creator})
        puts item.inspect
        choice = choices.create!(:item => item, :creator => creator)
        puts choice.inspect
      }
    end
  end

end
#@site = User.create!(:email => 'pius+7@alum.mit.edu', :password => 'password', :password_confirmation => 'password')
#@site.questions.create!(:name => 'what do you want?', :creator => @site.default_visitor)
