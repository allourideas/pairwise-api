require 'fastercsv'

class QuestionsController < InheritedResources::Base
  before_filter :authenticate
  respond_to :xml, :json
  respond_to :csv, :only => :export #leave the option for xml export here
  belongs_to :site, :optional => true

  def recent_votes_by_question_id
    creator_id = params[:creator_id]
    date = params[:date]
    if creator_id
	    questions = Question.find(:all, :select => :id, :conditions => { :local_identifier => creator_id})
	    questions_list = questions.map {|record | record.quoted_id}
	    question_votes_hash = Vote.with_question(questions_list).recent.count(:group => :question_id)

    elsif date #only for admins
	    question_votes_hash = Vote.recent(date).count(:group => :question_id)
    else
	    question_votes_hash = Vote.recent.count(:group => :question_id)
    end

    respond_to do |format|
    	format.xml{ render :xml => question_votes_hash.to_xml and return}
    end
  end

  def object_info_totals_by_question_id
      total_ideas_by_q_id = Choice.count(:include => ['item', 'question'], 
		          :conditions => "items.creator_id <> questions.creator_id", 
			  :group => "choices.question_id")

      active_ideas_by_q_id = Choice.count(:include => ['item', 'question'], 
		          :conditions => "choices.active = 1 AND items.creator_id <> questions.creator_id", 
			  :group => "choices.question_id")

      combined_hash = {}

      total_ideas_by_q_id.each do |q_id, num_total|
	      combined_hash[q_id] = {}
	      combined_hash[q_id][:total_ideas] = num_total
	      if(active_ideas_by_q_id.has_key?(q_id))
	         combined_hash[q_id][:active_ideas]= active_ideas_by_q_id[q_id]
	      else
	         combined_hash[q_id][:active_ideas]= 0
	      end
      end
    respond_to do |format|
	    format.xml { render :xml => combined_hash.to_xml and return}
    end

  end



  def show
    @question = Question.find(params[:id])
    visitor_identifier = params[:visitor_identifier]
    unless params[:barebones]
      
      @p = @question.choose_prompt(:algorithm => params[:algorithm])

      if @p.nil?
	      # could not find a prompt to choose
	      # I don't know the best http code for the api to respond, but 409 seems the closes
	      respond_to do |format|
              format.xml { render :xml => @question, :status => :conflict  and return} 
              format.json { render :json => @question, :status => :conflict and return} 
	      end

      end
      # @question.create_new_appearance - returns appearance, which we can then get the prompt from.
      # At the very least add 'if create_appearance is true,
      # we sometimes request a question when no prompt is displayed
      # TODO It would be a good idea to find these places and treat them like barebones
      if !visitor_identifier.blank? 
         visitor = current_user.visitors.find_or_create_by_identifier(visitor_identifier)
         @a = current_user.record_appearance(visitor, @p)
	 logger.info("creating appearance!")
      else 
	 @a = nil
      end
      
      left_choice_text = Proc.new { |options| options[:builder].tag!('left_choice_text', @p.left_choice.item.data) }
      right_choice_text = Proc.new { |options| options[:builder].tag!('right_choice_text', @p.right_choice.item.data) }
      picked_prompt_id = Proc.new { |options| options[:builder].tag!('picked_prompt_id', @p.id) }
      appearance_id = Proc.new { |options| options[:builder].tag!('appearance_id', @a.lookup) }
      
      visitor_votes = Proc.new { |options| options[:builder].tag!('visitor_votes', visitor.votes.count(:conditions => {:question_id => @question.id})) }
      visitor_ideas = Proc.new { |options| options[:builder].tag!('visitor_ideas', visitor.items.count) }
      
      the_procs = [left_choice_text, right_choice_text, picked_prompt_id]

      if @a
	  the_procs << appearance_id
	  the_procs << visitor_votes
	  the_procs << visitor_ideas
      end

      show! do |format|
        session['prompts_ids'] ||= []
        format.xml { 
          render :xml => @question.to_xml(:methods => [:item_count], :procs => the_procs)
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
    logger.info "all params are #{params.inspect}"
    logger.info "vi is #{params['question']['visitor_identifier']} and local are #{params['question']['local_identifier']}."
    if @question = current_user.create_question(params['question']['visitor_identifier'], :name => params['question']['name'], :local_identifier => params['question']['local_identifier'], :information => params['question']['information'], :ideas => (params['question']['ideas'].lines.to_a.delete_if {|i| i.blank?}))
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
    #expire_page :action => :index
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
  def export
    type = params[:type]
    response_type = params[:response_type]

    if response_type == 'redis'
	    redis_key = params[:redis_key]
    else
	    render :text => "Error! The only export type supported currently is local through redis!" and return
    end
    
    if type.nil?
	render :text => "Error! Specify a type of export" and return
    end

    @question = current_user.questions.find(params[:id])

    puts "redis key is::::: #{redis_key}"

    @question.send_later :export_and_delete, type, 
	                        :response_type => response_type, :redis_key => redis_key, :delete_at => 3.days.from_now


    render :text => "Ok! Please wait for the response (as specified by your response_type)"

#    export_type = params[:export_type]
#    export_format = params[:export_format] #CSV always now, could expand to xml later
  end

  def object_info_by_visitor_id
    
    object_type = params[:object_type]
    @question = current_user.questions.find(params[:id])

    visitor_id_hash = {}
    if object_type == "votes"
	    votes_by_visitor_id= Vote.all(:select => 'visitors.identifier as thevi, count(*) as the_votes_count', 
					  :joins => :voter, 
					  :conditions => {:question_id => @question.id }, 
					  :group => "voter_id")


	    votes_by_visitor_id.each do |visitor|
		    visitor_id_hash[visitor.thevi] = visitor.the_votes_count
	    end
    elsif object_type == "uploaded_ideas"

	    uploaded_ideas_by_visitor_id = @question.choices.find(:all, :select => 'creator_id, count(*) as ideas_count', 
								   :joins => [:item], 
								   :conditions => "items.creator_id != #{@question.creator_id}", 
	                                                           :group => 'creator_id')

	    count = 0
	    uploaded_ideas_by_visitor_id.each do |visitor|
		    v = Visitor.find(visitor.creator_id, :select => 'identifier') 

		    logger.info(v.identifier)
		    
		    if v.identifier.include?(" ") || v.identifier.include?("'")
			    v.identifier = "no_data#{count}"
			    count +=1
		    end
		    logger.info(v.identifier)

		    visitor_id_hash[v.identifier] = visitor.ideas_count
	    end

    elsif object_type == "bounces"

	    possible_bounces = @question.appearances.count(:group => :voter_id, :having => 'count_all = 1')
            possible_bounce_ids = possible_bounces.inject([]){|list, (k,v)| list << k}

	    voted_at_least_once = @question.votes.find(:all, :select => :voter_id, :conditions => {:voter_id => possible_bounce_ids})
	    voted_at_least_once_ids = voted_at_least_once.inject([]){|list, v| list << v.voter_id}

	    bounces = possible_bounce_ids - voted_at_least_once_ids

	    bounces.each do |visitor_id|
		    v = Visitor.find(visitor_id, :select => 'identifier') 

		    if v.identifier
		       visitor_id_hash[v.identifier] = 1
		    end
	    end
    end
    respond_to do |format|
    	format.xml{ render :xml => visitor_id_hash.to_xml and return}
    end
  end

  def all_num_votes_by_visitor_id
    scope = params[:scope]

    if scope == "all_votes"

	    votes_by_visitor_id= Vote.all(:select => 'visitors.identifier as thevi, count(*) as the_votes_count', 
					   :joins => :voter, 
					   :group => "voter_id")
	    visitor_id_hash = {}
	    votes_by_visitor_id.each do |visitor|
		    visitor_id_hash[visitor.thevi] = visitor.the_votes_count
		    visitor_id_hash[visitor.thevi] = visitor.the_votes_count
	    end
    elsif scope == "creators"

	    questions_created_by_visitor_id = Question.all(:select => 'visitors.identifier as thevi, count(*) as questions_count', 
							   :joins => :creator, 
							   :group => 'creator_id')
	    visitor_id_hash = {}
	    questions_created_by_visitor_id.each do |visitor|
		    visitor_id_hash[visitor.thevi] = visitor.questions_count
	    end

    end
    respond_to do |format|
    	format.xml{ render :xml => visitor_id_hash.to_xml and return}
    end
  end

  def object_info_totals_by_date
    object_type = params[:object_type]

    @question = current_user.questions.find(params[:id])
    if object_type == 'votes'
      hash = Vote.count(:conditions => "question_id = #{@question.id}", :group => "date(created_at)")
    elsif object_type == 'user_submitted_ideas'
      hash = Choice.count(:include => 'item', 
		          :conditions => "choices.question_id = #{@question.id} AND items.creator_id <> #{@question.creator_id}", 
			  :group => "date(choices.created_at)")
      # we want graphs to go from date of first vote -> date of last vote, so adding those two boundries here.
      mindate = Vote.minimum('date(created_at)', :conditions => {:question_id => @question.id})
      maxdate = Vote.maximum('date(created_at)', :conditions => {:question_id => @question.id})

      hash[mindate] = 0 if !hash.include?(mindate)
      hash[maxdate] = 0 if !hash.include?(maxdate)
    elsif object_type == 'user_sessions'
	    # little more work to do here:
      result = Vote.find(:all, :select => 'date(created_at) as date, voter_id, count(*) as vote_count', 
			 :conditions => "question_id = #{@question.id}", :group => 'date(created_at), voter_id')
      hash = Hash.new(0)
      result.each do |r|
	      hash[r.date]+=1
      end

    elsif object_type == 'appearances_by_creation_date'

            hash = Hash.new()
	    @question.choices.active.find(:all, :order => :created_at).each do |c|
	             relevant_prompts = c.prompts_on_the_left.find(:all, :select => 'id') + c.prompts_on_the_right.find(:all, :select => 'id')

		     appearances = Appearance.count(:conditions => {:prompt_id => relevant_prompts, :question_id => @question.id})

		     #initialize key to list if it doesn't exist
		     (hash[c.created_at.to_date] ||= []) << { :data => c.data, :appearances => appearances}
	    end

			     
    end

    respond_to do |format|
	    format.xml { render :xml => hash.to_xml and return}
    end
  end
  
  def all_object_info_totals_by_date
    object_type = params[:object_type]

    if object_type == 'votes'
      hash = Vote.count(:group => "date(created_at)")
    elsif object_type == 'user_submitted_ideas'
      hash = Choice.count(:include => ['item', 'question'], 
		          :conditions => "items.creator_id <> questions.creator_id", 
			  :group => "date(choices.created_at)")
    elsif object_type == 'user_sessions'
      result = Vote.find(:all, :select => 'date(created_at) as date, voter_id, count(*) as vote_count', 
			 :group => 'date(created_at), voter_id')
      hash = Hash.new(0)
      result.each do |r|
	      hash[r.date]+=1
      end
    end

    respond_to do |format|
	    format.xml { render :xml => hash.to_xml and return}
    end
  end

  protected 
end

class String
  unless defined? "".lines
    alias lines to_a
    #Ruby version compatibility
  end
end
