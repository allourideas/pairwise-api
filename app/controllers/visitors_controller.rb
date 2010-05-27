class VisitorsController < InheritedResources::Base
        respond_to :xml, :json
	before_filter :authenticate

	def objects_by_session_ids
		session_ids = params[:session_ids]

		visitor_ids = Visitor.find(:all, :conditions => { :identifier => session_ids})
		votes_by_visitor_id = Vote.with_voter_ids(visitor_ids).count(:group => :voter_id) 
		ideas_by_visitor_id = Item.with_creator_ids(visitor_ids).count(:group => :creator_id) 

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

end
