Rails.application.routes.draw do

  mount MissionControl::Jobs::Engine, at: "/jobs"

  # Locale switching
  patch "/locale", to: "locales#update", as: :locale

  # Authentication
  resource :session
  resources :passwords, param: :token

  # Registration
  resource :registration, only: [ :new, :create ]
  get "/sign_up", to: "registrations#new", as: :sign_up

  # Email Confirmation
  get "/confirm_email/:token", to: "email_confirmations#show", as: :confirm_email
  post "/resend_confirmation", to: "email_confirmations#resend", as: :resend_confirmation

  # Dashboard namespace (requires authentication)
  namespace :dashboard do
    root "businesses#show"

    # Onboarding flow
    resource :onboarding, only: [ :show, :update ], controller: "onboarding"

    resource :profile, only: [ :edit, :update ]
    resource :business, only: [ :show, :edit, :update ]
    resources :services do
      member do
        post :move_up
        post :move_down
      end
    end
    resources :bookings, only: [ :index, :show, :new, :create, :edit, :update ] do
      member do
        patch :confirm
        patch :start
        patch :complete
        patch :cancel
        patch :no_show
      end
    end
  end

  # Home
  get "home/index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  # get "up" => "/health#show", as: :rails_health_check
  get "/healthcheck", to: proc { [ 200, {}, [ "OK" ] ] }


  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Public booking routes (must be at the end to avoid conflicts)
  # React version of booking page
  get "/booking/:business_slug", to: "bookings#react_new", as: :react_booking, constraints: { business_slug: /[a-z0-9\-]+/ }

  # Stimulus version (original)
  get "/:business_slug", to: "bookings#react_new", as: :booking, constraints: { business_slug: /[a-z0-9\-]+/ }
  get "/:business_slug/availability", to: "bookings#availability"
  post "/:business_slug/bookings", to: "bookings#create"
  get "/:business_slug/bookings/:id", to: "bookings#show", as: :booking_confirmation

  # Defines the root path route ("/")
  root "home#index"
end
