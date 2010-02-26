class VisitorsController < InheritedResources::Base
        respond_to :xml, :json
	before_filter :authenticate
	def votes_by_session_ids
		session_ids = params[:session_ids]

		visitor_ids = Visitor.find(:all, :conditions => { :identifier => session_ids})
		votes_by_visitor_id = Vote.with_voter_ids(visitor_ids).count(:group => :voter_id) 

		votes_by_session_id = {}
		
		visitor_ids.each do |e| 
			if votes_by_visitor_id.has_key?(e.id)
				votes_by_session_id[e.identifier] = votes_by_visitor_id[e.id]
			end
		end
    		
		respond_to do |format|
    			format.xml{ render :xml => votes_by_session_id.to_xml and return}
    		end
	end

end
