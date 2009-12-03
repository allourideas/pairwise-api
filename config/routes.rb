ActionController::Routing::Routes.draw do |map|
  map.resources :clicks

  map.resources :prompts

  map.resources :items

  map.resources :choices

  map.resources :visitors

  map.resources :questions

  map.root :controller => "clearance/sessions", :action => "new"

  # rake routes
  # http://guides.rubyonrails.org/routing.html
end
