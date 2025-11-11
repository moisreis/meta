# === routes
#
# @author Moisés Reis
# @added 11/11/2025
# @package *Meta*
# @description Defines all route mappings for the application. It connects HTTP requests
#              to the appropriate **controllers** and **actions**. It organizes navigation flow
#              between authenticated and unauthenticated users using **Devise** helpers.
# @category *Routing*
#
# Usage:: - *[what]* maps application endpoints and manages user access flow
#         - *[how]* uses **Devise** to generate authentication routes and defines custom root paths
#                  depending on user authentication state
#         - *[why]* ensures users access the correct views and controllers according to their
#                  authentication status, maintaining consistent navigation throughout the app
#
# Attributes:: - *[:user]* @symbol - namespace key used by **Devise** to handle user sessions
#
Rails.application.routes.draw do
  devise_for :users

  devise_scope :user do
    # [Authenticated route] Defines the root path for logged-in users
    #                       and redirects to **HomeController#index**.
    authenticated :user do
      root 'home#index', as: :authenticated_root
    end

    # [Unauthenticated route] Defines the root path for guests
    #                         and redirects to **Devise::SessionsController#new**.
    unauthenticated do
      root 'devise/sessions#new', as: :unauthenticated_root
    end
  end
end
