# Defines URL routing and request dispatch rules for the Rails application.
#
# This file maps incoming HTTP requests to controller actions, including
# authentication flows, RESTful resources, dashboard routing, exports,
# asynchronous operations, and application-wide error handling.
#
# @author Moisés Reis

Rails.application.routes.draw do

  # ==========================================================================
  # AUTHENTICATION & USER MANAGEMENT
  # ==========================================================================

  devise_for :users,
             path: "auth",
             path_names: {
               sign_in: "login",
               sign_out: "logout",
               sign_up: "register"
             }

  resources :users
  resources :user_portfolio_permissions

  # ==========================================================================
  # ECONOMIC DATA & PERFORMANCE TRACKING
  # ==========================================================================

  resources :economic_index_histories, only: %i[index new create]
  resources :economic_indices
  resources :performance_histories, only: %i[index new create]

  # ==========================================================================
  # FUND OPERATIONS
  # ==========================================================================

  resources :fund_valuations, only: %i[index new create] do
    collection do
      get  :data_health
      post :trigger_import
      get  :import_progress
    end
  end

  resources :redemption_allocations

  resources :redemptions,
            only: %i[index edit update new create show destroy] do
    collection do
      get :export
    end
  end

  resources :applications

  # ==========================================================================
  # PORTFOLIO MANAGEMENT
  # ==========================================================================

  resources :portfolios do
    member do
      get  :monthly_report
      post :run_calculations
      get  :calculation_progress
    end

    collection do
      get :export
    end

    resources :checking_accounts
  end

  # ==========================================================================
  # INVESTMENT FUNDS & RELATED DATA
  # ==========================================================================

  resources :investment_fund_articles, only: %i[index new create]
  resources :normative_articles

  resources :investment_funds do
    collection do
      get :lookup
    end
  end

  resources :fund_investments,
            only: %i[index edit update destroy new create show] do
    collection do
      get :export
    end
  end

  # Non-RESTful endpoint used for historical market value lookup.
  get "fund_investments/:id/market_value_on",
      to: "fund_investments#market_value_on"

  # ==========================================================================
  # ERROR HANDLING & FALLBACK ROUTES
  # ==========================================================================

  get "errors/not_found"

  match "*path",
        to: "errors#show",
        via: :all,
        constraints: lambda { |request|
          !request.path.start_with?("/rails/") &&
            !request.path.start_with?("/investment_funds/lookup")
        }

  match "/403", to: "errors#show", via: :all
  match "/404", to: "errors#show", via: :all
  match "/500", to: "errors#show", via: :all

  get "/error/:code", to: "errors#show", as: :error

  # ==========================================================================
  # APPLICATION ROOT ROUTES
  # ==========================================================================

  devise_scope :user do
    authenticated :user do
      root "dashboard#index", as: :authenticated_root
    end

    unauthenticated do
      root "devise/sessions#new", as: :unauthenticated_root
    end
  end
end
