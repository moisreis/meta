# === application_controller
#
# @author Moisés Reis
# @added 11/13/2025
# @package *Meta*
# @description Defines the base controller that all other controllers inherit from.
#              Provides shared behavior, configuration, and security rules.
#              Ensures that features from **ActionController::Base** and authentication
#              from **Devise** integrate consistently across the app.
# @category *Controller*
#
# Usage:: - *[what]* This class serves as the foundational controller for the application.
#         - *[how]* It configures browser compatibility, manages cache invalidation
#                   when **Importmap** changes, and extends Devise parameters for user flows.
#         - *[why]* It centralizes behaviors that must apply to all controllers,
#                   ensuring consistency, security, and predictable request handling.
#
# Attributes:: - *devise_parameter_sanitizer* @object - provides extended Devise params
#
class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  stale_when_importmap_changes

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name])
  end
end