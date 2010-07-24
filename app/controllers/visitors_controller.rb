class VisitorsController < InheritedResources::Base
        respond_to :xml, :json
	before_filter :authenticate

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
	  votes = @visitor.votes(:include => [:choice, :loser_choice, :prompt]).order_by {|v| v.created_at}
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
