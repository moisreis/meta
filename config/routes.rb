Rails.application.routes.draw do
  get "errors/not_found"

  resources :economic_index_histories, only: [:index, :new, :create]

  resources :economic_indices

  devise_for :users, path: 'auth', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    sign_up: 'register'
  }

  resources :redemption_allocations

  resources :investment_fund_articles, only: [:index, :new, :create]

  resources :normative_articles

  resources :performance_histories, only: [:index, :new, :create]

  resources :fund_valuations, only: [:index, :new, :create] do
    collection do
      get :data_health
      post :trigger_import
    end
  end

  resources :redemptions, only: [:index, :edit, :update, :new, :create, :show] do
    collection do
      get :export
    end
  end

  resources :applications, only: [:index, :edit, :new, :create, :show]

  resources :user_portfolio_permissions

  resources :portfolios do
    member do
      get :monthly_report  # <-- ADD THIS
      post :run_calculations
    end
    collection do
      get :export
    end
  end

  resources :users

  resources :investment_funds

  resources :fund_investments, only: [:index, :edit, :update, :destroy, :new, :create, :show] do
    collection do
      get :export
    end
  end

  get 'fund_investments/:id/market_value_on', to: 'fund_investments#market_value_on'

  match "*path",
       to: "errors#show",
       via: :all,
       constraints: ->(req) { !req.path.starts_with?("/rails/") }

  match "/403", to: "errors#show", via: :all
  match "/404", to: "errors#show", via: :all
  match "/500", to: "errors#show", via: :all

  get "/error/:code", to: "errors#show", as: :error

  devise_scope :user do

    authenticated :user do
      root 'dashboard#index', as: :authenticated_root
    end

    unauthenticated do
      root 'devise/sessions#new', as: :unauthenticated_root
    end
  end
end