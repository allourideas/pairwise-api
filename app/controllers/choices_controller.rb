class ChoicesController < InheritedResources::Base
  respond_to :xml, :json
  actions :show, :index, :create, :update
  belongs_to :question
  has_scope :active, :boolean => true, :only => :index
  
  def index
    if params[:limit]
      @question = Question.find(params[:question_id])#, :include => :choices)
      @question.reload
      @question.choices.each(&:compute_score!)
      @choices = Choice.find(:all, :conditions => {:question_id => @question.id, :active => true}, :limit => params[:limit].to_i, :order => 'score DESC', :include => :item)
    else
      @question = Question.find(params[:question_id], :include => :choices) #eagerloads ALL choices
      @question.choices.each(&:compute_score!)
      @choices = @question.choices(true).active.find(:all, :include => :item)
    end
    index! do |format|
      format.xml { render :xml => params[:data].blank? ? @choices.to_xml(:methods => [:item_data, :votes_count]) : @choices.to_xml(:include => [:items], :methods => [:data, :votes_count])}
      format.json { render :json => params[:data].blank? ? @choices.to_json : @choices.to_json(:include => [:items]) }
    end

  end
  
  def show
    show! do |format|
      format.xml { 
        @choice.reload
        @choice.compute_score!
        @choice.reload
        render :xml => @choice.to_xml(:methods => [:item_data, :wins_plus_losses, :question_name])}
      format.json { render :json => @choice.to_json(:methods => [:data])}
    end 
  end
  
  def single
    @question = current_user.questions.find(params[:question_id])
    @prompt = @question.prompts.pick
    show! do |format|
      format.xml { render :xml => @prompt.to_xml}
      format.json { render :json => @prompt.to_json}
    end
  end
  
  
  def create_from_abroad
    authenticate
    logger.info "inside create_from_abroad"

    @question = Question.find params[:question_id]

    respond_to do |format|
      if @choice = current_user.create_choice(params['params']['data'], @question, {:data => params['params']['data'], :local_identifier => params['params']['local_identifier']})
        saved_choice_id = Proc.new { |options| options[:builder].tag!('saved_choice_id', @choice.id) }
        choice_status = Proc.new { |options| 
          the_status = @choice.active? ? 'active' : 'inactive'
          options[:builder].tag!('choice_status', the_status) }
        logger.info "successfully saved the choice #{@choice.inspect}"
        format.xml { render :xml => @question.picked_prompt.to_xml(:methods => [:left_choice_text, :right_choice_text], :procs => [saved_choice_id, choice_status]), :status => :ok }
        format.json { render :json => @question.picked_prompt.to_json, :status => :ok }
      else
        format.xml { render :xml => @choice.errors, :status => :unprocessable_entity }
        format.json { render :json => @choice.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def update_from_abroad
    authenticate
    @question = current_user.questions.find(params[:question_id])
    @choice = @question.choices.find(params[:id])
    
    respond_to do |format|
      if @choice.activate!
        logger.info "successfully activated choice #{@choice.inspect}"
        format.xml { render :xml => true }
        format.json { render :json => true }
      else
         logger.info "failed to activate choice  #{@choice.inspect}"
        format.xml { render :xml => @choice.to_xml(:methods => [:data, :votes_count, :wins_plus_losses])}
        format.json { render :json => @choice.to_json(:methods => [:data])}
      end
    end
  end
  
  def activate
    authenticate
    @question = current_user.questions.find(params[:question_id])
    @choice = @question.choices.find(params[:id])
    respond_to do |format|
      if @choice.activate!
        format.xml { render :xml => @choice.to_xml, :status => :created }
        format.json { render :json => @choice.to_json, :status => :created }
      else
        format.xml { render :xml => @choice.errors, :status => :unprocessable_entity }
        format.json { render :json => @choice.to_json }
      end
    end
  end


    def suspend
      authenticate
      @question = current_user.questions.find(params[:question_id])
      @choice = @question.choices.find(params[:id])
      respond_to do |format|
        if @choice.suspend!
          format.xml { render :xml => @choice.to_xml, :status => :created }
          format.json { render :json => @choice.to_json, :status => :created }
        else
          format.xml { render :xml => @choice.errors, :status => :unprocessable_entity }
          format.json { render :json => @choice.to_json }
        end
      end
    end
    
  
  def skip
    voter = User.by_sid(params['params']['auto'])
    logger.info "#{voter.inspect} is skipping."
    @question = Question.find(params[:question_id])
    @prompt = @question.prompts.find(params[:id])
    respond_to do |format|
      if @skip = voter.skip(@prompt)
        format.xml { render :xml =>  @question.picked_prompt.to_xml(:methods => [:left_choice_text, :right_choice_text]), :status => :ok }
        format.json { render :json => @question.picked_prompt.to_json, :status => :ok }
      else
        format.xml { render :xml => c, :status => :unprocessable_entity }
        format.json { render :json => c, :status => :unprocessable_entity }
      end
    end
  end
end
