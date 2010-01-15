class QuestionsController < InheritedResources::Base
  respond_to :xml, :json
  belongs_to :site, :optional => true
  #has_scope :voted_on_by

  def show
    @question = Question.find(params[:id])
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
  end
  
  def create
    authenticate
    logger.info "vi is #{params['question']['visitor_identifier']} and local are #{params['question']['local_identifier']}.  all params are #{params.inspect}"
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
end


class String
  unless defined? "".lines
    alias lines to_a
    #Ruby version compatibility
  end
end