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

  # Admin namespace (ThemBooking staff only)
  namespace :admin do
    root "dashboard#index"

    get "sign_in", to: "sessions#new", as: :sign_in
    post "sign_in", to: "sessions#create"
    delete "sign_out", to: "sessions#destroy", as: :sign_out

    resources :users, except: [ :new, :create ]
    resources :businesses, except: [ :new, :create ]
    resources :staffs
  end

  # Dashboard namespace (requires authentication)
  namespace :dashboard do
    root "branches#index"

    # Onboarding flow
    resource :onboarding, only: [ :show, :update ], controller: "onboarding"

    resource :profile, only: [ :edit, :update ]
    resource :business, only: [ :show, :edit, :update ] do
      resources :gallery_photos, only: [ :index, :create, :update, :destroy ]
      resource :landing_page, only: [ :edit, :update ], controller: "landing_page"
    end
    resources :branches do
      member do
        post :enable_independence
      end
      resource :open_hour, only: [ :show, :edit, :update ]
      resources :service_categories, only: [ :index, :new, :create, :edit, :update, :destroy ]
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
      resource :operations, only: [ :show ] do
        member do
          get :data
          get :services_list
        end
      end
      resources :business_closures, only: [ :index, :create, :destroy ]
    end
  end

  # Home
  get "home/index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  # get "up" => "/health#show", as: :rails_health_check
  get "/healthcheck", to: proc { [ 200, {}, [ "OK" ] ] }
  get "/up", to: proc { [ 200, {}, [ "OK" ] ] }


  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Public routes (must be at the end to avoid conflicts)
  # Business landing page — constraint checks business slug first (single indexed EXISTS query)
  get "/:slug", to: "landing_pages#show", as: :landing_page,
      constraints: ->(req) { Business.exists?(slug: req.params[:slug]) }

  # Business-level booking routes
  get "/booking/:business_slug", to: "bookings#react_new", as: :booking, constraints: { business_slug: /[a-z0-9\-]+/ }
  get "/booking/:business_slug/availability", to: "bookings#availability"
  post "/booking/:business_slug/bookings", to: "bookings#create"
  get "/booking/:business_slug/bookings/:id", to: "bookings#show", as: :booking_confirmation

  # Defines the root path route ("/")
  root "home#index"
end
