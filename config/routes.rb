# === routes
#
# @author Moisés Reis
# @added 11/11/2025
# @package Meta
# @description Configures the application's URL structure and maps incoming requests
#              to the appropriate controllers. It sets up standard routes for **Portfolio**
#              and **User** resources and customizes the root URL based on whether a user
#              is currently logged in.
# @category *System*
#
# Usage:: - *[what]* Defines all routable paths within the application.
#         - *[how]* Utilizes the **Rails router** DSL, including the `resources` macro to
#                   establish seven routes per resource and `devise_for` for authentication routes.
#                   It uses the `devise_scope` helper to direct authenticated users to
#                   **DashboardController#index** and unauthenticated users to
#                   **Devise::SessionsController#new**.
#         - *[why]* Establishes the application's primary navigational structure, ensuring
#                   that all user interactions and URL requests correctly map to the backend
#                   processing logic.
#
# Attributes:: - *portfolios_path* @route - Standard CRUD routes for the **Portfolio** resource.
#              - *users_path* @route - Standard CRUD routes for the **User** resource.
#              - *new_user_session_path* @route - Standard authentication routes provided by **Devise**.
#              - *authenticated_root_path* @route - The root path for logged-in users, pointing to **DashboardController#index**.
#              - *unauthenticated_root_path* @route - The root path for guest users, pointing to **Devise::SessionsController#new**.
#
Rails.application.routes.draw do
  resources :portfolios
  resources :users
  devise_for :users

  devise_scope :user do
    # [Authenticated route] Defines the root path for logged-in users
    #                       and redirects to **HomeController#index**.
    authenticated :user do
      root 'dashboard#index', as: :authenticated_root
    end

    # [Unauthenticated route] Defines the root path for guests
    #                         and redirects to **Devise::SessionsController#new**.
    unauthenticated do
      root 'devise/sessions#new', as: :unauthenticated_root
    end
  end
end
