require 'fastercsv'
require 'generator.rb'

class QuestionsController < InheritedResources::Base
  actions :all, :except => [ :show, :edit, :delete ]
  before_filter :authenticate
  respond_to :xml, :json
  respond_to :csv, :only => :export #leave the option for xml export here
  belongs_to :site, :optional => true

  def show
    @question = current_user.questions.find(params[:id])

    begin
        @question_optional_information = @question.get_optional_information(params)
    rescue RuntimeError
	respond_to do |format|
           format.xml { render :xml => @question.to_xml, :status => :conflict and return} 
	end
    end

    optional_information = []
    @question_optional_information.each do |key, value|
      optional_information << Proc.new { |options| options[:builder].tag!(key, value)}
    end

    respond_to do |format|
      format.xml { 
        render :xml => @question.to_xml(:methods => [:item_count], :procs => optional_information)
      }
      format.js{
      	render :json => @question.to_json(:methods => [:item_count], :procs => optional_information)
      }
    end
  end
  
  def create
    logger.info "all params are #{params.inspect}"
    logger.info "vi is #{params['question']['visitor_identifier']} and local are #{params['question']['local_identifier']}."
    if @question =
        current_user.create_question(
          params['question']['visitor_identifier'],
          :name => params['question']['name'],
          :local_identifier => params['question']['local_identifier'],
          :information => params['question']['information'],
          :ideas => (params['question']['ideas'].lines.to_a.delete_if {|i| i.blank?} rescue nil)
         )
      respond_to do |format|
        format.xml { render :xml => @question.to_xml}
      end
    else
      respond_to do |format|
        format.xml { render :xml => @question.errors.to_xml}
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

    # puts "redis key is::::: #{redis_key}"

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
    elsif object_type == "skips"
	    skips_by_visitor_id= Skip.all(:select => 'visitors.identifier as thevi, count(*) as the_votes_count', 
					  :joins => :skipper, 
					  :conditions => {:question_id => @question.id }, 
					  :group => "skipper_id")


	    skips_by_visitor_id.each do |visitor|
		    visitor_id_hash[visitor.thevi] = visitor.the_votes_count
	    end
    elsif object_type == "uploaded_ideas"

	    uploaded_ideas_by_visitor_id = @question.choices.find(:all, :select => 'creator_id, count(*) as ideas_count', 
								   :conditions => "choices.creator_id != #{@question.creator_id}",
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
    elsif object_type == 'skips'
      hash = Skip.count(:conditions => {:question_id => @question.id}, :group => "date(created_at)")
    elsif object_type == 'user_submitted_ideas'
      hash = Choice.count(:conditions => "choices.question_id = #{@question.id} AND choices.creator_id <> #{@question.creator_id}", 
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
      hash = Choice.count(:include => :question, 
		          :conditions => "choices.creator_id <> questions.creator_id", 
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

  def update
    # prevent AttributeNotFound error and only update actual Question columns, since we add extra information in 'show' method
    question_attributes = Question.new.attribute_names
    params[:question] = params[:question].delete_if {|key, value| !question_attributes.include?(key)}
    @question = current_user.questions.find(params[:id])
    update!
  end

  def index
    @questions = current_user.questions.scoped({})
    @questions = @questions.created_by(params[:creator]) if params[:creator]

    counts = {}
    if params[:user_ideas]
      counts['user-ideas'] = Choice.count(:joins => :question,
                                         :conditions => "choices.creator_id <> questions.creator_id",
                                         :group => "choices.question_id")
    end
    if params[:active_user_ideas]
      counts['active-user-ideas'] = Choice.count(:joins => :question,
                                                :conditions => "choices.active = 1 AND choices.creator_id <> questions.creator_id",
                                                :group => "choices.question_id")
    end
    if params[:votes_since]
      counts['recent-votes'] = Vote.count(:joins => :question,
                                         :conditions => ["votes.created_at > ?", params[:votes_since]],
                                         :group => "votes.question_id")
    end

    # There doesn't seem to be a good way to add procs to an array of
    # objects. This  solution  depends on Array#to_xml rendering each
    # member in the correct order. Internally, it just uses, #each, so
    # this _should_ work.
    ids = Generator.new{ |g|  @questions.each{ |q| g.yield q.id } }
    extra_info = Proc.new do |o|
      id = ids.next
      counts.each_pair do |attr, hash|
        o[:builder].tag!(attr, hash[id] || 0 , :type => "integer")
      end
    end

    index! do |format|
      format.xml do
        render :xml => @questions.to_xml(:procs => [ extra_info ])
      end
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
