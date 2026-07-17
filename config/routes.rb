Rails.application.routes.draw do
  devise_for :users
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

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "new_scan", to: "pages#new_scan"
  get "scan_history", to: "pages#scan_history"
  resources :scans, only: %i[create show]
  get "up" => "rails/health#show", as: :rails_health_check
  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
