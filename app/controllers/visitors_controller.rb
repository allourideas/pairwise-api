class VisitorsController < InheritedResources::Base
        respond_to :xml, :json
	before_filter :authenticate
  actions :index

  def index
    cond = params[:question_id] ? "question_id = #{params[:question_id]}" : nil

    counts = {}
    if params[:votes_count]
      counts[:votes_count] = Vote.count(:conditions => cond, :group => "voter_id")
    end
    if params[:skips_count]
      counts[:skips_count] = Skip.count(:conditions => cond, :group => "skipper_id")
    end
    if params[:ideas_count]    
      idea_cond = "choices.creator_id != questions.creator_id" + 
        (cond ? " AND #{cond}" : "")
      counts[:ideas_count] = Choice.count(:joins => :question,
                                          :conditions => idea_cond,
                                          :group => "choices.creator_id")
    end
    if params[:bounces]
      counts[:bounces] = Appearance.count(:conditions => cond,
                                          :group => "voter_id",
                                          :having => "count(answerable_id) = 0")
    end
    if params[:questions_created]
      counts[:questions_created] = Question.count(:group => :creator_id)
    end

    # visitors belong to a site, so we can't just scope them to a question.
    # instead, take the union of visitor ids with counted objects
    if counts.empty?
      @visitors = current_user.visitors.scoped({})
    else      
      ids = counts.inject([]){ |ids,(k,v)| ids | v.keys }
      @visitors = current_user.visitors.scoped(:conditions => { :id => ids })
    end

    counts.each_pair do |attr,values|
      @visitors.each{ |v| v[attr] = values[v.id] || 0 }
    end
      
    index!
  end

	def objects_by_session_ids
		session_ids = params[:session_ids]

		visitor_ids = Visitor.find(:all, :conditions => { :identifier => session_ids})
		votes_by_visitor_id = Vote.with_voter_ids(visitor_ids).count(:group => :voter_id) 
		ideas_by_visitor_id = Choice.count(:group => :creator_id) 

		objects_by_session_id = {}
		
		visitor_ids.each do |e| 
			if votes_by_visitor_id.has_key?(e.id)
				objects_by_session_id[e.identifier] = Hash.new
				objects_by_session_id[e.identifier]['votes'] = votes_by_visitor_id[e.id]
			end
			if ideas_by_visitor_id.has_key?(e.id)
				objects_by_session_id[e.identifier] = Hash.new if objects_by_session_id[e.identifier].nil?
				objects_by_session_id[e.identifier]['ideas'] = ideas_by_visitor_id[e.id]
			end
		end
    		
		respond_to do |format|
    			format.json { render :json => objects_by_session_id.to_json and return}
    		end
	end

	def votes
	  @visitor = Visitor.find_by_identifier!(params[:id])
	  votes = Vote.find(:all, :include => [:choice, :loser_choice, :prompt], 
				  :conditions => {:question_id => params[:question_id],
					          :voter_id => @visitor.id
	  				         },
				  :order => 'created_at ASC')
	  response = []

	  votes.each do |vote|
	    winner = (vote.prompt.left_choice_id == vote.choice_id ? 'left' : 'right')
	    if vote.choice_id == vote.prompt.left_choice_id
	      left_choice  = vote.choice
	      right_choice = vote.loser_choice
      else
        left_choice  = vote.loser_choice
        right_choice = vote.choice
      end
	    vote_response = {
	      :winner            => winner,
	      :id                => vote.id,
	      :left_choice_id    => left_choice.id,
        :left_choice_data  => left_choice.data,
        :right_choice_id   => right_choice.id,
        :right_choice_data => right_choice.data
	    }
	    response << vote_response
    end

    render :json => {:votes => response}.to_json
  end
end
