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
    @question = Question.find(params[:question_id])

    @prompt = @question.prompts.find(params[:id]) #, :include => [{ :left_choice => :item }, { :right_choice => :item }])

    time_viewed = params['params']['time_viewed']
    raise "time_viewed cannot be nil" if time_viewed.nil?

    visitor_identifier = params['params']['auto']
    raise "visitor identifier cannot be nil" if visitor_identifier.nil?
    appearance_lookup = params['params']['appearance_lookup']
    raise "appearance_lookup cannot be nil" if appearance_lookup.nil?

    skip_reason = params['params']['skip_reason'] # optional parameter
    

    respond_to do |format|
      if @skip = current_user.record_skip(visitor_identifier, appearance_lookup, @prompt, time_viewed, :skip_reason => skip_reason) 
       
       #This is not hte right way to do this. See def vote for a better example
       begin
          @next_prompt = @question.choose_prompt
       rescue RuntimeError

           respond_to do |format|
              format.xml { render :xml => @prompt.to_xml, :status => :conflict and return} 
           end
       end

        visitor = current_user.visitors.find_or_create_by_identifier(visitor_identifier)
        @a = current_user.record_appearance(visitor, @next_prompt)
         
	appearance_id = Proc.new { |options| options[:builder].tag!('appearance_id', @a.lookup) }
      
	visitor_votes = Proc.new { |options| options[:builder].tag!('visitor_votes', visitor.votes.count(:conditions => {:question_id => @question.id})) }
        visitor_ideas = Proc.new { |options| options[:builder].tag!('visitor_ideas', visitor.items.count) }


        format.xml { render :xml =>  @next_prompt.to_xml(:procs => [appearance_id, visitor_votes, visitor_ideas],:methods => [:left_choice_text, :right_choice_text]), :status => :ok }
        format.json { render :json => @next_prompt.to_json, :status => :ok }
      else
        format.xml { render :xml => @prompt.to_xml, :status => :conflict}
        format.json { render :json => @prompt.to_xml, :status => :conflict}
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
