# === application_controller
#
# @author Moisés Reis
# @added 11/13/2025
# @package *Meta*
# @description Defines the base controller for the entire application.
#              Ensures shared configuration and behavior are inherited across all controllers.
#              Integrates **Devise** authentication and manages browser compatibility and cache state.
#              Extends parameter sanitization to allow additional user attributes during registration and account updates.
# @category *Controller*
#
# Usage:: - *[what]* defines global controller-level configuration and authentication rules.
#         - *[how]* inherits from **ActionController::Base** to provide filters and parameter configuration for **Devise**.
#                   Uses `before_action` to invoke a method that permits additional attributes in user-related forms.
#         - *[why]* centralizes logic that should be shared across all controllers, improving maintainability, consistency, and authentication reliability.
#
# Attributes:: - *allow_browser* @macro - Restricts access to modern browsers for better compatibility and performance.
#              - *stale_when_importmap_changes* @method - Triggers cache invalidation when the **Importmap** asset configuration changes.
#              - *configure_permitted_parameters* @method - Extends **Devise**’s strong parameters to include custom user fields (`first_name`, `last_name`).
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
