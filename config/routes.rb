Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # Incident replay routes
  resources :incidents do
    collection do
      get :replay
      post :start_replay
      post :pause_replay
      post :resume_replay
      post :clear_all
      get :suggestions
      get :transcript
      get :timeline
    end
  end
  
  # Suggestions routes
  get "suggestions/index"
  get "suggestions/create"

  # Defines the root path route ("/")
  root "incidents#index"
end
