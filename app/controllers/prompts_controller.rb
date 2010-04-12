class PromptsController < InheritedResources::Base
  respond_to :xml, :json
  actions :show, :index
  belongs_to :question
  has_scope :active, :boolean => true, :only => :index
  
  has_scope :voted_on_by
  #before_filter :authenticate
  
  
  def activate
    # turning off auth for now: @question = current_user.questions.find(params[:question_id])
    @question = Question.find(params[:question_id])
    @prompt = @question.prompts.find(params[:id])
    respond_to do |format|
      if @prompt.activate!
        format.xml { render :xml => @choice.to_xml, :status => :created }
        format.json { render :json => @choice.to_json, :status => :created }
      else
        format.xml { render :xml => @choice.errors, :status => :unprocessable_entity }
        format.json { render :json => @choice.to_json }
      end
    end
  end
  
  def vote
    #NOT IMPLEMENTED
    @question = Question.find(params[:question_id])
    @prompt = @question.prompts.find(params[:id])
    @choices = @prompt.choices.active
    @choice = @choices[params[:index]]
    respond_to do |format|
      format.xml { render :xml => @choice.to_xml }
      format.json { render :json => @choice.to_xml }
    end
  end
  
  def vote_left
    vote_direction(:left)
  end
  
  
  def vote_right
    vote_direction(:right)
  end
  
  
  def vote_direction(direction)
    authenticate
  
    logger.info "#{current_user.inspect} is voting #{direction} at #{Time.now}."
    @question = Question.find(params[:question_id])
    @prompt = @question.prompts.find(params[:id])

    time_viewed = params['params']['time_viewed']

    visitor_identifier = params['params']['auto']
    
    appearance_lookup = params['params']['appearance_lookup']
    
    case direction
    when :left
      successful = c = current_user.record_vote(params['params']['auto'], appearance_lookup, @prompt, 0, time_viewed)
    when :right
      successful = c = current_user.record_vote(params['params']['auto'], appearance_lookup, @prompt, 1, time_viewed)
    else
      raise "need to specify either ':left' or ':right' as a direction"
    end
    
    #@prompt.choices.each(&:compute_score!)
    respond_to do |format|
      if successful
	catchup_marketplace_ids = [120, 117, 1, 116]
	if catchup_marketplace_ids.include?(@question.id)
		logger.info("Question #{@question.id} is using catchup algorithm!")
		next_prompt = @question.catchup_choose_prompt
	else
		next_prompt = @question.picked_prompt
	end


        @a = current_user.record_appearance(visitor_identifier, next_prompt)
         
	appearance_id = Proc.new { |options| options[:builder].tag!('appearance_id', @a.lookup) }

        format.xml { render :xml => next_prompt.to_xml(:procs => [appearance_id], :methods => [:left_choice_text, :right_choice_text, :left_choice_id, :right_choice_id]), :status => :ok }
        format.json { render :json => next_prompt.to_json(:procs => [appearance_id], :methods => [:left_choice_text, :right_choice_text, :left_choice_id, :right_choice_id]), :status => :ok }
      else
        format.xml { render :xml => c, :status => :unprocessable_entity }
        format.json { render :json => c, :status => :unprocessable_entity }
      end
    end
  end
  
  
  
  
  
  def suspend
    @question = current_user.questions.find(params[:question_id])
    @prompt = @question.prompts.find(params[:id])
    respond_to do |format|
      if @prompt.suspend!
        format.xml { render :xml => @prompt.to_xml, :status => :created }
        format.json { render :json => @prompt.to_json, :status => :created }
      else
        format.xml { render :xml => @prompt.errors, :status => :unprocessable_entity }
        format.json { render :json => @prompt.to_json }
      end
    end
  end
  
  
  
  def skip
    authenticate
    logger.info "#{current_user.inspect} is skipping."
    @question = Question.find(params[:question_id])
    @prompt = @question.prompts.find(params[:id], :include => [{ :left_choice => :item }, { :right_choice => :item }])
    

    respond_to do |format|
      if @skip = current_user.record_skip(params['params']['auto'], @prompt)
        format.xml { render :xml =>  @question.picked_prompt.to_xml(:methods => [:left_choice_text, :right_choice_text]), :status => :ok }
        format.json { render :json => @question.picked_prompt.to_json, :status => :ok }
      else
        format.xml { render :xml => @skip, :status => :unprocessable_entity }
        format.json { render :json => @skip, :status => :unprocessable_entity }
      end
    end
  end
  

  # GET /prompts
  # ==== Return
  # Array of length n. Prompts matching parameters
  # ==== Options (params)
  # question_id<String>:: Converted to integer. Must be greater than 0 and
  # belong to the current user.  Must belong to user.
  # item_ids<String>:: Comma seperated list of items to include. May only
  # include commas and digits.  Must belong to user.  Optional value.
  # data<String>:: Flag for whether to include item data.  Data included
  # if value is not nil.
  # ==== Raises
  # PermissionError:: If question or any item doesn't belong to current user.
  
  def index
    # turning off auth for now: @question = current_user.questions.find(params[:question_id])
    #authenticate
    @question = Question.find(params[:question_id])
    @prompts = @question.prompts
    #raise @question.inspect
    index! do |format|
      if !params[:voter_id].blank?
        format.xml { render :xml => User.find(params[:voter_id]).prompts_voted_on.to_xml(:include => [:items, :votes], 
                                                                                          :methods => [ :active_items_count, 
                                                                                                        :all_items_count, 
                                                                                                        :votes_count ]) }
        format.json { render :json => User.find(params[:voter_id]).prompts_voted_on.to_json(:include => [:items, :votes], 
                                                                            :methods => [ :active_items_count, 
                                                                                          :all_items_count, 
                                                                                          :votes_count ]) }
      else
        format.xml { render :xml => params[:data].blank? ? 
                                    @prompts.to_xml : 
                                    @prompts.to_xml(:include => [:items]) 
                                    }
        format.json { render :json => params[:data].blank? ? @prompts.to_json : @prompts.to_json(:include => [:items]) }
      end
    end
  end
  
  def show
    @question = Question.find(params[:question_id])
    @prompt = @question.prompts.find(params[:id], :include => [{ :left_choice => :item }, { :right_choice => :item }])
    show! do |format|
      format.xml { render :xml => @prompt.to_xml(:methods => [:left_choice_text, :right_choice_text])}
      format.json { render :json => @prompt.to_json(:methods => [:left_choice_text, :right_choice_text])}
    end
  end

  
  protected
    def begin_of_association_chain
      current_user.questions.find(params[:question_id])
    end
    
    def collection
      if params[:choice_id].blank?
        @prompts
      else
        end_of_association_chain.with_choice_id(params[:choice_id])
      end
    end
end
