# frozen_string_literal: true

# config/routes.rb
#
# Defines all application routes and request dispatch rules.
#
# Maps incoming HTTP requests to controller actions, including
# authentication flows, resource management, exports, reporting,
# asynchronous operations, and error handling.
#
# @author  Moisés Reis

Rails.application.routes.draw do

  # == Authentication & User Management ======================================

  devise_for :users, path: "auth", path_names: {
               sign_in: "login",
               sign_out: "logout",
               sign_up: "register"
             }

  resources :users
  resources :user_portfolio_permissions


  # == Economic Data & Performance Tracking ==================================

  resources :economic_index_histories, only: %i[index new create]
  resources :economic_indices
  resources :performance_histories, only: %i[index new create]


  # == Fund Operations ========================================================

  # -- Fund Valuations --------------------------------------------------------

  resources :fund_valuations, only: %i[index new create] do
    collection do
      get  :data_health
      post :trigger_import
      get  :import_progress
    end
  end

  # -- Redemptions ------------------------------------------------------------

  resources :redemption_allocations

  resources :redemptions, only: %i[index edit update new create show destroy] do
    collection do
      get :export
    end
  end

  # -- Applications -----------------------------------------------------------

  resources :applications


  # == Portfolio Management ===================================================

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


  # == Investment Funds & Related Data =======================================

  # -- Articles & Normatives -------------------------------------------------

  resources :investment_fund_articles, only: %i[index new create]
  resources :normative_articles

  # -- Investment Funds -------------------------------------------------------

  resources :investment_funds do
    collection do
      get :lookup
    end
  end

  # -- Fund Investments -------------------------------------------------------

  resources :fund_investments, only: %i[index edit update destroy new create show] do
    collection do
      get :export
    end
  end

  # -- Historical Lookups ----------------------------------------------------

  get "fund_investments/:id/market_value_on", to: "fund_investments#market_value_on"


  # == Error Handling =========================================================

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


  # == Root Routes ============================================================

  devise_scope :user do
    authenticated :user do
      root "dashboard#index", as: :authenticated_root
    end

    unauthenticated do
      root "devise/sessions#new", as: :unauthenticated_root
    end
  end

end