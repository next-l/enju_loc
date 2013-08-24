Rails.application.routes.draw do
  resources :loc_search, :only => [:index, :create]
end
