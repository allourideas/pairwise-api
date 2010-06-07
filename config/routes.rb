ActionController::Routing::Routes.draw do |map|
  #map.resources :clicks
  map.resources :densities
  map.resources :visitors, :collection => {:objects_by_session_ids => :post}
  map.resources :questions, :member => { :object_info_totals_by_date => :get, 
	  				 :object_info_by_visitor_id => :get, 
					 :export => :post, 
					 :set_autoactivate_ideas_from_abroad => :put,  
					 :activate => :put, 
					 :suspend => :put}, 
			    :collection => {:all_num_votes_by_visitor_id => :get, 
					    :all_object_info_totals_by_date => :get,
					    :object_info_totals_by_question_id => :get,
				            :recent_votes_by_question_id => :get} do |question|
    question.resources :items
    question.resources :prompts, :member => {:skip => :post, :vote => :post}, 
                       :collection => {:single => :get, :index => :get}
    question.resources :choices, :member => {:flag => :put}, :collection => {:create_from_abroad => :post}
  end
  map.resources :algorithms
  map.connect "/questions/:question_id/prompts/:id/vote/:index", :controller => 'prompts', :action => 'vote'

  
  
  
  map.learn '/learn', :controller => 'home', :action => 'learn'
  map.api '/api', :controller => 'home', :action => 'api'
  map.about '/about', :controller => 'home', :action => 'about'
  map.root :controller => "clearance/sessions", :action => "new"

  # rake routes
  # http://guides.rubyonrails.org/routing.html
end
