# Defines the routing logic and URL mapping for the Rails application.
#
# This file configures RESTful resources, authentication scopes,
# custom error handling, and dashboard root definition and redirection.
#
# TABLE OF CONTENTS:
#
# 1. Authentication & Users
# 2. Financial Resources
#   2a. Core Financial Data
#   2b. Fund Operations
# 3. Portfolio & Funds
#   3a. Portfolio Management
#   3b. Fund Data & Investments
# 4. Utilities & Error Handling
# 5. Root Definition
#
# @author Moisés Reis

Rails.application.routes.draw do

  # =============================================================
  #                  1. AUTHENTICATION & USERS
  # =============================================================

  devise_for :users, path: 'auth', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    sign_up: 'register'
  }

  resources :users
  resources :user_portfolio_permissions

  # =============================================================
  #                 2a. CORE FINANCIAL DATA
  # =============================================================

  resources :economic_index_histories, only: [:index, :new, :create]
  resources :economic_indices
  resources :performance_histories, only: [:index, :new, :create]

  # =============================================================
  #                   2b. FUND OPERATIONS
  # =============================================================

  resources :fund_valuations, only: [:index, :new, :create] do
    collection do
      get :data_health
      post :trigger_import
      get  :import_progress
    end
  end

  resources :redemption_allocations

  resources :redemptions, only: [:index, :edit, :update, :new, :create, :show, :destroy] do
    collection do
      get :export
    end
  end

  resources :applications

  # =============================================================
  #                 3a. PORTFOLIO MANAGEMENT
  # =============================================================

  resources :portfolios do
    member do
      get :monthly_report
      post :run_calculations
      get  :calculation_progress
    end
    collection do
      get :export
    end
    resources :checking_accounts
  end

  # =============================================================
  #              3b. FUND DATA & INVESTMENTS
  # =============================================================

  resources :investment_fund_articles, only: [:index, :new, :create]
  resources :normative_articles

  resources :investment_funds do
    collection { get :lookup }
  end

  resources :fund_investments, only: [:index, :edit, :update, :destroy, :new, :create, :show] do
    collection do
      get :export
    end
  end

  # Non-RESTful endpoint for historical market value lookup.
  get 'fund_investments/:id/market_value_on',
      to: 'fund_investments#market_value_on'

  # =============================================================
  #                4. UTILITIES & ERROR HANDLING
  # =============================================================

  get "errors/not_found"

  match "*path",
        to: "errors#show",
        via: :all,
        constraints: ->(req) {
          !req.path.starts_with?("/rails/") &&
          !req.path.start_with?("/investment_funds/lookup")
        }

  match "/403", to: "errors#show", via: :all
  match "/404", to: "errors#show", via: :all
  match "/500", to: "errors#show", via: :all

  get "/error/:code", to: "errors#show", as: :error

  # =============================================================
  #                      5. ROOT DEFINITION
  # =============================================================

  devise_scope :user do
    authenticated :user do
      root 'dashboard#index', as: :authenticated_root
    end

    unauthenticated do
      root 'devise/sessions#new', as: :unauthenticated_root
    end
  end
end
