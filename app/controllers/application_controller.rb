# === application_controller
#
# @author Moisés Reis
# @added 11/24/2025
# @package *Meta*
# @description This controller serves as the base class for all other controllers
#              in the application. It establishes universal configurations, such as
#              security policies and permitted parameters for authentication using **Devise**.
# @category *Controller*
#
# Usage:: - *[What]* This code block defines the foundational behavior that every
#           page request handler (controller) inherits and uses automatically.
#         - *[How]* It extends the core framework functions from **ActionController::Base**
#           and executes global checks before specific actions run in child controllers.
#         - *[Why]* It ensures consistent security, modern browser compatibility,
#           and authentication handling across the entire application without
#           duplicating code.
#
class ApplicationController < ActionController::Base

  # Explanation:: This command tells the browser to only allow the application
  #               to run on modern web browser versions, rejecting outdated or
  #               potentially vulnerable older browsers.
  allow_browser versions: :modern

  # Explanation:: This function automatically checks if any referenced external assets
  #               (like JavaScript or CSS imports) have changed. If they have, it forces
  #               browsers to load the new versions instead of using old, cached files.
  stale_when_importmap_changes

  # Explanation:: This runs the `configure_permitted_parameters` method before
  #               any action handled by **Devise** (like user sign-up or profile update)
  #               to ensure only safe data fields are accepted from the user form.
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # == configure_permitted_parameters
  #
  # @author Moisés Reis
  # @category *Security*
  #
  # Security:: This method customizes the list of fields that the
  #            authentication system (**Devise**) accepts. It adds `first_name` and
  #            `last_name` to the default fields to allow user registration and profile updates.
  #
  # Attributes:: - *@first_name* - The user's first name, added to the permitted list.
  #              - *@last_name* - The user's last name, added to the permitted list.
  #
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(
      :sign_up,
      keys: %i[first_name last_name]
    )
    devise_parameter_sanitizer.permit(
      :account_update,
      keys: %i[first_name last_name]
    )
  end
end