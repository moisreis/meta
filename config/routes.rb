Rails.application.routes.draw do
  resources :redemptions
  resources :applications
  resources :user_portfolio_permissions
  resources :portfolios
  resources :users
  resources :investment_funds
  resources :fund_investments

  devise_for :users

  devise_scope :user do
    authenticated :user do
      root 'dashboard#index', as: :authenticated_root
    end

    unauthenticated do
      root 'devise/sessions#new', as: :unauthenticated_root
    end
  end
end
