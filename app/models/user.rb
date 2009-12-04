class User < ActiveRecord::Base
  include Clearance::User
  has_many :visitors, :class_name => "Visitor", :foreign_key => "site_id"
  has_many :questions, :class_name => "Question", :foreign_key => "site_id"
  has_many :clicks, :class_name => "Click", :foreign_key => "site_id"
  has_many :items, :class_name => "Item", :foreign_key => "site_id"
  
  def default_visitor
    visitors.find(:first, :conditions => {:identifier => 'owner'})
  end
  
  def create_question(visitor_identifier, question_params)
    puts "the question_params are #{question_params.inspect}"
    visitor = visitors.find_or_create_by_identifier(visitor_identifier)
    question = visitor.questions.create(question_params.merge(:site => self))
  end
  
  def create_choice(visitor_identifier, question, choice_params = {})
    visitor = visitors.find_or_create_by_identifier(visitor_identifier)
    raise "Question not found" if question.nil?
    if visitor.owns?(question)
      choice = question.choices.create!(choice_params.merge(:active => true, :creator => visitor))
    elsif question.local_identifier == choice_params[:local_identifier]
      choice = question.choices.create!(choice_params.merge(:active => true, :creator => visitor))
    else
      choice = question.choices.create!(choice_params.merge(:active => false, :creator => visitor))
    end
    notify_question_owner_that_new_choice_has_been_added(choice)
    return choice
  end
  
  def record_vote(visitor_identifier, prompt, ordinality)
    visitor = visitors.find_or_create_by_identifier(visitor_identifier)
    visitor.vote_for!(prompt, ordinality)
    prompt.choices.each {|c| c.score = c.compute_score; c.save!}
  end
  
  def record_skip(visitor_identifier, prompt)
    visitor = visitors.find_or_create_by_identifier(visitor_identifier)
    question = prompt.question
    visitor.skip!(prompt)
  end
  
  def activate_question(question_id, options)
    question = questions.find(question_id)
    question.activate!
  end
  
  def activate_choice(choice_id, options)
    choice = Choice.find(choice_id)
    choice.activate!
  end
  
  def deactivate_choice(choice_id, options)
    choice = Choice.find(choice_id)
    choice.deactivate!
  end
  
  def deactivate_question(question_id, options)
    question = questions.find(question_id)
    question.deactivate!
  end
  
  def after_create
    visitors.create!(:site => self, :identifier => 'owner')
  end
  
  private
  
  def notify_question_owner_that_new_choice_has_been_added(choice)
    #ChoiceNotifier.deliver_notification(choice) #this may be the responsibility of the client
  end
end
