class ChoicesController < InheritedResources::Base
  respond_to :xml, :json
  actions :show, :index, :create, :update, :new
  belongs_to :question
  has_scope :active, :type => :boolean, :only => :index

  before_filter :authenticate
  
  def index
    if params[:limit]
      @question = current_user.questions.find(params[:question_id])

      find_options = {:conditions => {:question_id => @question.id},
		      :limit => params[:limit].to_i, 
		      :order => 'score DESC'
		      }
      
      find_options[:conditions].merge!(:active => true) unless params[:include_inactive]
      find_options.merge!(:offset => params[:offset]) if params[:offset]

      @choices = Choice.find(:all, find_options)

    else
      @question = current_user.questions.find(params[:question_id], :include => :choices) #eagerloads ALL choices
      unless params[:include_inactive]
        @choices = @question.choices(true).active.find(:all)
      else
        @choices = @question.choices.find(:all)
      end
    end
    index! do |format|
      format.xml { render :xml => @choices.to_xml(:only => [ :data, :score, :id, :active, :created_at, :wins, :losses], :methods => :user_created)}
    end

  end
  
  def votes
    @choice = Choice.find(params[:id])
    render :xml => @choice.votes.to_xml
  end

  # Similar finds similar choices as the choice given for the question.
  # Currently, it only returns choices that are identical.
  def similar
    @question = current_user.questions.find(params[:question_id])
    choice = @question.choices.find(params[:id])
    @similar = @question.choices.active.find(:all, :conditions => ["data = ? and id <> ?", choice.data, choice.id])
    render :xml => @similar.to_xml
  end

  def create
    
    visitor_identifier = params[:choice].delete(:visitor_identifier)

    visitor = current_user.default_visitor 
    if visitor_identifier
      visitor = current_user.visitors.find_or_create_by_identifier(visitor_identifier)
    end
    params[:choice].merge!(:creator => visitor)

    @question = current_user.questions.find(params[:question_id])
    params[:choice].merge!(:question_id => @question.id)


    @choice = Choice.new(params[:choice])
    create!
  end
  
  def flag
    @question = current_user.questions.find(params[:question_id])
    @choice = @question.choices.find(params[:id])

    flag_params = {:choice_id => params[:id].to_i, :question_id => params[:question_id].to_i, :site_id => current_user.id}

    if explanation = params[:explanation] 
	    flag_params.merge!({:explanation => explanation})
		   
    end
    if visitor_identifier = params[:visitor_identifier]
            visitor = current_user.visitors.find_or_create_by_identifier(visitor_identifier)
	    flag_params.merge!({:visitor_id => visitor.id})
    end
    respond_to do |format|
	    if @choice.deactivate!
                    flag = Flag.create!(flag_params)
		    format.xml { render :xml => @choice.to_xml, :status => :created }
		    format.json { render :json => @choice.to_json, :status => :created }
	    else
		    format.xml { render :xml => @choice.errors, :status => :unprocessable_entity }
		    format.json { render :json => @choice.to_json }
	    end
    end

  end

  def update
    # prevent AttributeNotFound error and only update actual Choice columns, since we add extra information in 'show' method
    choice_attributes = Choice.new.attribute_names
    params[:choice] = params[:choice].delete_if {|key, value| !choice_attributes.include?(key)}
    Choice.transaction do
      # lock question since we'll need a lock on it later in Choice.update_questions_counter
      @question = current_user.questions.find(params[:question_id], :lock => true)
      @choice = @question.choices.find(params[:id])
      update!
    end
  end

  def show
    @question = current_user.questions.find(params[:question_id])
    @choice = @question.choices.find(params[:id])
    response_options = {}
    response_options[:include] = :versions if params[:version] == 'all'

    respond_to do |format|
      format.xml { render :xml => @choice.to_xml(response_options) }
      format.json { render :json => @choice.to_json(response_options) }
    end
  end


end
  
