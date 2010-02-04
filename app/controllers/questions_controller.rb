class QuestionsController < InheritedResources::Base
  respond_to :xml, :json
  belongs_to :site, :optional => true
  #has_scope :voted_on_by

  def show
    @question = Question.find(params[:id])
    unless params[:barebones]
      @p = @question.picked_prompt
      left_choice_text = Proc.new { |options| options[:builder].tag!('left_choice_text', @p.left_choice.item.data) }
      right_choice_text = Proc.new { |options| options[:builder].tag!('right_choice_text', @p.right_choice.item.data) }
      picked_prompt_id = Proc.new { |options| options[:builder].tag!('picked_prompt_id', @p.id) }
      show! do |format|
        session['prompts_ids'] ||= []
        format.xml { 
          render :xml => @question.to_xml(:methods => [:item_count], :procs => [left_choice_text, right_choice_text, picked_prompt_id])
          }
      end
    else
      show! do |format|
        session['prompts_ids'] ||= []
        format.xml { 
          render :xml => @question.to_xml(:methods => [:item_count])
        }
      end
    end
  end
  
  def create
    authenticate
    logger.info "all params are #{params.inspect}"
    logger.info "vi is #{params['question']['visitor_identifier']} and local are #{params['question']['local_identifier']}."
    if @question = current_user.create_question(params['question']['visitor_identifier'], :name => params['question']['name'], :local_identifier => params['question']['local_identifier'], :ideas => (params['question']['ideas'].lines.to_a.delete_if {|i| i.blank?}))
      respond_to do |format|
        format.xml { render :xml => @question.to_xml}
      end
    else
      respond_to do |format|
        format.xml { render :xml => @question.errors.to_xml}
      end
    end
  end

  def set_autoactivate_ideas_from_abroad
    authenticate
    expire_page :action => :index
    logger.info("INSIDE autoactivate ideas")

    
    @question = current_user.questions.find(params[:id])
    @question.it_should_autoactivate_ideas = params[:question][:it_should_autoactivate_ideas]

    respond_to do |format|
      if @question.save
        logger.info "successfully set this question to autoactive ideas #{@question.inspect}"
        format.xml { render :xml => true }
        format.json { render :json => true}
      else
        logger.info "Some error in saving question, #{@question.inspect}"
        format.xml { render(:xml => false) and return}
        format.json { render :json => false }
      end
    end

  end
end

class String
  unless defined? "".lines
    alias lines to_a
    #Ruby version compatibility
  end
end
