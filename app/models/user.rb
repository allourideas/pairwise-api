class User < ActiveRecord::Base
  include Clearance::User
  has_many :visitors, :class_name => "Visitor", :foreign_key => "site_id"
  has_many :questions, :class_name => "Question", :foreign_key => "site_id"
  has_many :clicks, :class_name => "Click", :foreign_key => "site_id"
  
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
  
  def record_vote(options)
    visitor_identifier = options.delete(:visitor_identifier)
    if visitor_identifier.nil?
       visitor = default_visitor
    else
       visitor = visitors.find_or_create_by_identifier(visitor_identifier)
    end
    visitor.vote_for!(options)
  end

  def record_appearance(visitor, prompt)
    algorithm_name = prompt.algorithm[:name] || prompt.algorithm['name'] unless prompt.algorithm.nil?
    Appearance.create(:voter => visitor, :prompt => prompt, :question_id => prompt.question_id, :site_id => self.id, :lookup =>  Digest::MD5.hexdigest(rand(10000000000).to_s + visitor.id.to_s + prompt.id.to_s), :algorithm_metadata => prompt.algorithm.to_json, :algorithm_name => algorithm_name )
  end

  
  def record_skip(options)
    visitor_identifier = options.delete(:visitor_identifier)
    if visitor_identifier.nil?
      visitor = default_visitor
    else
      visitor = visitors.find_or_create_by_identifier(visitor_identifier)
    end
    visitor.skip!(options)
  end
  
  def activate_question(question_id, options)
    question = questions.find(question_id)
    question.activate!
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
