require 'fastercsv'

class QuestionsController < InheritedResources::Base
  respond_to :xml, :json
  respond_to :csv, :only => :export #leave the option for xml export here
  belongs_to :site, :optional => true

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
  def export
    authenticate

    type = params[:type]

    if type == 'votes'
    	export_votes
    elsif type == 'items'
    	export_items
    else
	render :text => "Error! Specify a type of export"
    end
#    export_type = params[:export_type]
#    export_format = params[:export_format] #CSV always now, could expand to xml later
  end
  

  protected 
  def export_votes
    @question = Question.find(params[:id])

    outfile = "question_#{@question.id}_votes" + Time.now.strftime("%m-%d-%Y") + ".csv"
    headers = ['Vote ID', 'Voter ID', 'Question ID','Winner ID', 'Winner Text', 'Loser ID', 'Loser Text',
	    	'Prompt ID', 'Left Choice ID', 'Right Choice ID', 'Created at', 'Updated at']
    @votes = @question.votes
    csv_data = FasterCSV.generate do |csv|
       csv << headers	
       @votes.each do |v|
	       prompt = v.prompt
	       # these may not exist
	       loser_data = v.loser_choice.nil? ? "" : "'#{v.loser_choice.data.strip}'"
	       left_id = v.prompt.nil? ? "" : v.prompt.left_choice_id
	       right_id = v.prompt.nil? ? "" : v.prompt.right_choice_id

	       csv << [ v.id, v.voter_id, v.question_id, v.choice_id, "\'#{v.choice.data.strip}'", v.loser_choice_id, loser_data,
		       v.prompt_id, left_id, right_id, v.created_at, v.updated_at] 
       end
    end

    send_data(csv_data,
        :type => 'text/csv; charset=iso-8859-1; header=present',
      :disposition => "attachment; filename=#{outfile}")
  end

  def export_items
    @question = Question.find(params[:id], :include => [:choices, :prompts])

    outfile = "question_#{@question.id}_items_" + Time.now.strftime("%m-%d-%Y") + ".csv"
    headers = ['Choice ID', 'Item ID', 'Data', 'Question ID', 'User Submitted', 'Choice Creator ID', 
	    	'Wins', 'Losses', 'Created at', 'Updated at', 'Active', 'Score', 'Local Identifier', 
		'Prompts on Left', 'Prompts on Right', 'Prompts Count']

    csv_data = FasterCSV.generate do |csv|
       csv << headers	
       @question.choices.each do |c|
	       csv << [ c.id, c.item_id, "'#{c.data.strip}'", c.question_id, c.item.creator != @question.creator, c.item.creator_id, 
		       c.wins, c.losses, c.created_at, c.updated_at, c.active, c.score, c.local_identifier, 
		       c.prompts_on_the_left(true).size, c.prompts_on_the_right(true).size, c.prompts_count]
       end
    end

    send_data(csv_data,
        :type => 'text/csv; charset=iso-8859-1; header=present',
      :disposition => "attachment; filename=#{outfile}")
  end
end

class String
  unless defined? "".lines
    alias lines to_a
    #Ruby version compatibility
  end
end
