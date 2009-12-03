class ChoicesController < InheritedResources::Base
  respond_to :xml, :json
  actions :show, :index, :create, :update
  belongs_to :question
  has_scope :active, :boolean => true, :only => :index
  
  
  def create_from_abroad
    authenticate
    logger.info "inside create_from_abroad"

    @question = Question.find params[:question_id]
    # @visitor = Visitor.find_or_create_by_identifier(params['params']['sid'])
    # @item = current_user.items.create({:data => params['params']['data'], :creator => @visitor}
    # @choice = @question.choices.build(:item => @item, :creator => @visitor)

    respond_to do |format|
      if @choice = current_user.create_choice(params['params']['data'], @question, {:data => params['params']['data']})
        saved_choice_id = Proc.new { |options| options[:builder].tag!('saved_choice_id', @choice.id) }
        logger.info "successfully saved the choice #{@choice.inspect}"
        format.xml { render :xml => @question.picked_prompt.to_xml(:methods => [:left_choice_text, :right_choice_text], :procs => [saved_choice_id]), :status => :ok }
        format.json { render :json => @question.picked_prompt.to_json, :status => :ok }
      else
        format.xml { render :xml => @choice.errors, :status => :unprocessable_entity }
        format.json { render :json => @choice.errors, :status => :unprocessable_entity }
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
