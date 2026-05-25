# Defines URL routing and request dispatch rules for the Rails application.
#
# This file maps incoming HTTP requests to controller actions, including
# authentication flows, RESTful resources, dashboard routing, exports,
# asynchronous operations, and application-wide error handling.
#
# Responsibilities:
# - Define authentication routes for Devise with custom path names.
# - Declare RESTful resources for all domain models.
# - Configure member and collection routes for non-standard actions.
# - Route error status codes and unknown paths to the errors controller.
# - Set authenticated and unauthenticated application root paths.
#
# This file does not define controller logic, authorization rules,
# or request validation. Those concerns belong in controllers,
# policies, and form objects respectively.
#
# @author Moisés Reis

Rails.application.routes.draw do

  # =============================================================
  #               AUTHENTICATION & USER MANAGEMENT
  # =============================================================

  devise_for :users, path: "auth", path_names: {
               sign_in: "login",
               sign_out: "logout",
               sign_up: "register"
             }

  resources :users
  resources :user_portfolio_permissions

  # =============================================================
  #               ECONOMIC DATA & PERFORMANCE TRACKING
  # =============================================================

  resources :economic_index_histories, only: %i[index new create]
  resources :economic_indices
  resources :performance_histories, only: %i[index new create]

  # =============================================================
  #                        FUND OPERATIONS
  # =============================================================

  # --- FUND VALUATIONS -----------------------------------------

  resources :fund_valuations, only: %i[index new create] do
    collection do
      get  :data_health
      post :trigger_import
      get  :import_progress
    end
  end

  # --- REDEMPTIONS ---------------------------------------------

  resources :redemption_allocations

  resources :redemptions, only: %i[index edit update new create show destroy] do
    collection do
      get :export
    end
  end

  # --- APPLICATIONS --------------------------------------------

  resources :applications

  # =============================================================
  #                      PORTFOLIO MANAGEMENT
  # =============================================================

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

  # =============================================================
  #                INVESTMENT FUNDS & RELATED DATA
  # =============================================================

  # --- ARTICLES & NORMATIVES -----------------------------------

  resources :investment_fund_articles, only: %i[index new create]
  resources :normative_articles

  # --- INVESTMENT FUNDS ----------------------------------------

  resources :investment_funds do
    collection do
      get :lookup
    end
  end

  # --- FUND INVESTMENTS ----------------------------------------

  resources :fund_investments, only: %i[index edit update destroy new create show] do
    collection do
      get :export
    end
  end

  # --- HISTORICAL LOOKUPS --------------------------------------

  get "fund_investments/:id/market_value_on", to: "fund_investments#market_value_on"

  # =============================================================
  #                ERROR HANDLING & FALLBACK ROUTES
  # =============================================================

  get "errors/not_found"

  match "*path", to: "errors#show",
        via: :all,
        constraints: lambda { |request|
          !request.path.start_with?("/rails/") &&
            !request.path.start_with?("/investment_funds/lookup")
        }

  match "/403", to: "errors#show", via: :all
  match "/404", to: "errors#show", via: :all
  match "/500", to: "errors#show", via: :all

  get "/error/:code", to: "errors#show", as: :error

  # =============================================================
  #                    APPLICATION ROOT ROUTES
  # =============================================================

  devise_scope :user do
    authenticated :user do
      root "dashboard#index", as: :authenticated_root
    end

    unauthenticated do
      root "devise/sessions#new", as: :unauthenticated_root
    end
  end
end
