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
    logger.info "the question_params are #{question_params.inspect}"
    visitor = visitors.find_or_create_by_identifier(visitor_identifier)
    question = visitor.questions.create(question_params.merge(:site => self))
  end
  
  def create_choice(visitor_identifier, question, choice_params = {})
    visitor = visitors.find_or_create_by_identifier(visitor_identifier)
    raise "Question not found" if question.nil?

    #TODO Does this serve a purpose?
    if visitor.owns?(question)
      choice = question.choices.create!(choice_params.merge(:active => false, :creator => visitor))
    elsif question.local_identifier == choice_params[:local_identifier]
      choice = question.choices.create!(choice_params.merge(:active => false, :creator => visitor))
    else
      choice = question.choices.create!(choice_params.merge(:active => false, :creator => visitor))
    end
    notify_question_owner_that_new_choice_has_been_added(choice)
    return choice
  end
  
  def record_vote(visitor_identifier, appearance_lookup, prompt, ordinality, time_viewed)
    #@click = Click.new(:what_was_clicked => 'on the API level, inside record_vote' + " with prompt id #{prompt.id}, ordinality #{ordinality.to_s}")
    #@click.save!
    visitor = visitors.find_or_create_by_identifier(visitor_identifier)
    visitor.vote_for!(appearance_lookup, prompt, ordinality, time_viewed)
    #prompt.choices.each {|c| c.compute_score; c.save!}
  end

  def record_appearance(visitor, prompt)
    a = Appearance.create(:voter => visitor, :prompt => prompt, :question_id => prompt.question_id, 
			  :lookup =>  Digest::MD5.hexdigest(rand(10000000000).to_s + visitor.id.to_s + prompt.id.to_s) )
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
