ActionController::Routing::Routes.draw do |map|
  map.resources :densities, :only => :index
  map.resources :visitors, :only => :index,
                           :collection => {:objects_by_session_ids => :post},
                           :member => {:votes => :get}
  map.resources :questions, :except => [:edit, :destroy],
                            :member => {:object_info_totals_by_date => :get, 
	  				:object_info_by_visitor_id => :get, 
					    :median_votes_per_session => :get,
              :vote_rate => :get,
              :median_responses_per_session => :get,
              :votes_per_uploaded_choice => :get,
              :upload_to_participation_rate => :get,
                                        :export => :post} , 
			    :collection => {:all_num_votes_by_visitor_id => :get, 
					    :all_object_info_totals_by_date => :get,
					    :site_stats => :get,
					    :object_info_totals_by_question_id => :get,
				            :recent_votes_by_question_id => :get} do |question|
      question.resources :prompts, :only => :show,
                                   :member => {:skip => :post, :vote => :post}
      question.resources :choices, :only => [:show, :index, :create, :update, :new],
                                   :member => {:flag => :put, :votes => :get}
    end

  map.root :controller => "clearance/sessions", :action => "new"

end
