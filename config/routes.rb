Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }
  root to: "pages#home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resources :offers, only: %i[index]
  resources :orders, only: %i[index show create]
  resource :token, only: %i[show]

  namespace :webhooks do
    post "stripe", to: "stripe#create"
  end

  namespace :admin do
    resources :users, only: %i[index edit update destroy]
  end

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resource :me, only: [:show], controller: "me"
      resources :scans, only: [:create]
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "dashboard", to: "pages#dashboard"
  get "news", to: "pages#news"
  get "tricks_and_tips", to: "pages#tricks_and_tips"
  get "new_scan", to: "pages#new_scan"
  get "scan_history", to: "pages#scan_history"
  get "profile", to: "pages#profile"
  post "profile/regenerate_extension_token", to: "pages#regenerate_extension_token", as: :regenerate_extension_token
  resources :scans, only: %i[create show]
  get "up" => "rails/health#show", as: :rails_health_check
  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
