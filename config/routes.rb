# === routes
#
# @author Moisés Reis
# @added 12/3/2025
# @package *Meta*
# @description This file defines all the application's URL paths and maps them to
#              specific actions within the **Controllers**. It includes authentication
#              routes provided by **Devise** and resource routes for managing data entities.
# @category *Model*
#
# Usage:: - *[What]* This code block determines how incoming web requests are handled by the application.
#         - *[How]* It uses the **Rails Routing Engine** to match HTTP verbs and paths to **Controller** actions and establishes resource-based URLs.
#         - *[Why]* It is essential for defining the public-facing structure of the application and directing user interactions to the correct backend logic.
#
# Attributes:: - *path* @string - The base path segment for all Devise authentication routes.
#              - *path_names* @hash - A mapping that customizes the URL names for specific Devise actions.
#
Rails.application.routes.draw do
  resources :economic_index_histories
  resources :economic_indices

  # Explanation:: This line sets up all necessary routes for user authentication
  #               using the **Devise** gem. It customizes the base path to `/auth`
  #               and changes the default URL segments to use `login`, `logout`, and `register`.
  devise_for :users, path: 'auth', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    sign_up: 'register'
  }

  # Explanation:: This line establishes the seven standard RESTful routes
  #               (index, show, new, create, edit, update, destroy) for the **RedemptionAllocation** resource.
  #               These routes map to the actions within the **RedemptionAllocationsController**.
  resources :redemption_allocations

  # Explanation:: This line creates the standard RESTful routes for the **InvestmentFundArticle**
  #               resource, allowing administrators to manage articles related to investment funds.
  #               It maps directly to the **InvestmentFundArticlesController** actions.
  resources :investment_fund_articles

  # Explanation:: This line defines the RESTful routes for the **NormativeArticle** resource,
  #               providing paths for managing regulatory and normative documents.
  #               These paths are handled by the **NormativeArticlesController**.
  resources :normative_articles

  # Explanation:: This line generates the RESTful routes for the **PerformanceHistory** resource.
  #               It provides the means to create, view, and manage historical performance data records.
  resources :performance_histories

  # Explanation:: This line sets up the standard RESTful routes for the **FundValuation** resource.
  #               It defines the URL endpoints for managing and displaying the valuation data of funds.
  resources :fund_valuations do
    collection do
      get :data_health
      post :trigger_import
    end
  end

  # Explanation:: This line establishes the RESTful routes for the **Redemption** resource.
  #               It allows the application to handle and process routes related to user redemption requests.
  resources :redemptions do
    collection do
      get :export
    end
  end

  # Explanation:: This line generates the RESTful routes for the **Application** resource.
  #               It provides the necessary paths for managing and tracking user investment application processes.
  resources :applications

  # Explanation:: This line creates the RESTful routes for the **UserPortfolioPermission** resource.
  #               It enables the application to manage and define access rights between users and portfolios.
  resources :user_portfolio_permissions

  # Explanation:: This line defines the seven standard RESTful routes for the main **Portfolio** resource.
  #               These routes map to the **PortfoliosController** for managing user investment portfolios.
  resources :portfolios do
    collection do
      get :export
    end
  end

  # Explanation:: This line establishes the standard RESTful routes for the administrative **User** resource.
  resources :users

  # Explanation:: This line generates the RESTful routes for the **InvestmentFund** resource.
  #               It defines the paths required for managing and displaying the master list of investment funds.
  resources :investment_funds

  # Explanation:: This line sets up the RESTful routes for the **FundInvestment** resource.
  #               It provides the mechanism for managing individual investment allocations within funds.
  resources :fund_investments do
    collection do
      get :export
    end
  end

  # Explanation:: This block provides scope to define custom routes that depend on the user's
  #               authentication status, utilizing the **Devise** helpers.
  devise_scope :user do

    # Explanation:: This block specifies the root path that the application uses when a user
    #               is successfully logged in. It directs them to the `index` action of the **DashboardController**.
    authenticated :user do
      root 'dashboard#index', as: :authenticated_root
    end

    # Explanation:: This block specifies the root path that the application uses when no user
    #               is currently logged in. It directs unauthenticated users to the **Devise** login screen.
    unauthenticated do
      root 'devise/sessions#new', as: :unauthenticated_root
    end
  end
end