ActionController::Routing::Routes.draw do |map|
  #map.resources :clicks
  map.resources :visitors, :collection => {:votes_by_session_ids => :get}
  map.resources :questions, :member => { :object_info_totals_by_date => :get, :num_votes_by_visitor_id => :get, :export => :post, :set_autoactivate_ideas_from_abroad => :put,  :activate => :put, :suspend => :put}, :collection => {:recent_votes_by_question_id => :get} do |question|
    question.resources :items
    question.resources :prompts, :member => {:vote_left => :post, :vote_right => :post, :skip => :post, :vote => :post}, 
                       :collection => {:single => :get, :index => :get}
    question.resources :choices, :member => { :activate => :put, :suspend => :put, :update_from_abroad => :put, :deactivate_from_abroad => :put }, :collection => {:create_from_abroad => :post}
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
