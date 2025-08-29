Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API Gateway routes
  namespace :api do
    namespace :v1 do
      post 'secret_santa/generate_assignments', to: 'secret_santa#generate_assignments'
      get 'secret_santa/check_status/:request_id', to: 'secret_santa#check_assignment_status'
      get 'secret_santa/health', to: 'secret_santa#health'
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
