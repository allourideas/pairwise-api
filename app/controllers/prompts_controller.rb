class PromptsController < InheritedResources::Base
  respond_to :xml, :json
  actions :show
  belongs_to :question
  
  has_scope :voted_on_by
  before_filter :authenticate
  
    # To record a vote 
    #  required parameters - prompt id, ordinality, visitor_identifer?
    #  optional params - visitor_identifier, appearance_lookup
    # After recording vote, next prompt display parameters:
    #   same as in show  - :with_prompt, with_appearance, with visitor_stats, etc
  def vote
    @question = current_user.questions.find(params[:question_id])
    @prompt = @question.prompts.find(params[:id])
    
    vote_options = params[:vote] || {}
    vote_options.merge!(:prompt => @prompt, :question => @question)

    successful = object= current_user.record_vote(vote_options)
    optional_information = []
    if params[:next_prompt]
       begin
           params[:next_prompt].merge!(:with_prompt => true) # We always want to get the next possible prompt
           @question_optional_information = @question.get_optional_information(params[:next_prompt])
       rescue RuntimeError

           respond_to do |format|
              format.xml { render :xml => @prompt.to_xml, :status => :conflict and return} 
           end
       end
       object = @question.prompts.find(@question_optional_information.delete(:picked_prompt_id))
       @question_optional_information.each do |key, value|
          optional_information << Proc.new { |options| options[:builder].tag!(key, value)}
       end
    end

    respond_to do |format|
      if !successful.nil?
        format.xml { render :xml => object.to_xml(:procs => optional_information , :methods => [:left_choice_text, :right_choice_text, :left_choice_id, :right_choice_id]), :status => :ok }
        format.json { render :json => object.to_json(:procs => optional_information, :methods => [:left_choice_text, :right_choice_text, :left_choice_id, :right_choice_id]), :status => :ok }
      else
        format.xml { render :xml => @prompt.to_xml, :status => :unprocessable_entity }
        format.json { render :json => @prompt.to_xml, :status => :unprocessable_entity }
      end
    end
  end
  
  def skip
    logger.info "#{current_user.inspect} is skipping."
    @question = current_user.questions.find(params[:question_id])
    @prompt = @question.prompts.find(params[:id])

    skip_options = params[:skip] || {}
    skip_options.merge!(:prompt => @prompt, :question => @question)

    successful = response = current_user.record_skip(skip_options)
    optional_information = []
    if params[:next_prompt]
       begin
           params[:next_prompt].merge!(:with_prompt => true) # We always want to get the next possible prompt
           @question_optional_information = @question.get_optional_information(params[:next_prompt])
       rescue RuntimeError

           respond_to do |format|
              format.xml { render :xml => @prompt.to_xml, :status => :conflict and return} 
           end
       end
       response = @question.prompts.find(@question_optional_information.delete(:picked_prompt_id))
       @question_optional_information.each do |key, value|
          optional_information << Proc.new { |options| options[:builder].tag!(key, value)}
       end
    end
    respond_to do |format|
      if !successful.nil?
        format.xml { render :xml => response.to_xml(:procs => optional_information , :methods => [:left_choice_text, :right_choice_text, :left_choice_id, :right_choice_id]), :status => :ok }
        format.json { render :json => response.to_json(:procs => optional_information, :methods => [:left_choice_text, :right_choice_text, :left_choice_id, :right_choice_id]), :status => :ok }
      else
        format.xml { render :xml => @prompt.to_xml, :status => :unprocessable_entity }
        format.json { render :json => @prompt.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  def show
    @question = current_user.questions.find(params[:question_id])
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
