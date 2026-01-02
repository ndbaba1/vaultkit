Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      resources :orgs, param: :org_slug, only: [] do
        resources :datasources, only: [:index, :show, :create, :update] do
          resource :scan, only: [:create], controller: "datasources/scans"
        end
        resources :scans, only: [:create]
        resources :policy_bundles, only: [:create], param: :bundle_version do
          post :activate, on: :member
          post :rollback, on: :member
        end
        resources :requests, only: [:create, :index]
        resources :approvals, only: [:index] do
          post :approve, on: :member
          post :deny,    on: :member
        end
        resources :grants, only: [] do
          post :fetch, on: :member
        end
      end
    end
  end

  devise_for :users,
    path: 'api/users',
    defaults: { format: :json },
    controllers: {
      sessions: 'api/users/sessions',
      registrations: 'api/users/registrations'
    }

    match "/404", to: "api/v1/base#not_found", via: :all
    match "/500", to: "api/v1/base#internal_error", via: :all  
end
