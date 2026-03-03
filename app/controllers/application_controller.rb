# === application_controller.rb
#
# @author Moisés Reis
# @added 03/03/2026
# @package *Meta*
# @description This file acts as the foundation for all other controllers
#              within the application, holding shared logic and security
#              rules that apply to every part of the web interface.
# @category *Controller*
#
# Usage:: - *[What]* A central command center that defines how the website
#           behaves for every visitor and logged-in user.
#         - *[How]* It uses built-in **Rails** tools to check browser
#           versions and manage user permissions automatically.
#         - *[Why]* Keeping these rules here ensures the website stays
#           secure and consistent without repeating code elsewhere.
#
# Attributes:: - *[allow_browser]* @method - limits access to modern browsers
#              - *[stale_when_importmap_changes]* @method - updates assets
#              - *[configure_permitted_parameters]* @method - handles user data
#
class ApplicationController < ActionController::Base

  # This line ensures the website only works on updated and
  # secure web browsers to protect the user's information.
  allow_browser versions: :modern

  # This command tells the browser to download the latest
  # styles and scripts whenever the app receives an update.
  stale_when_importmap_changes

  # This instruction checks if a user is trying to sign in
  # or sign up before allowing certain data to be saved.
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # == configure_permitted_parameters
  #
  # @author Moisés Reis
  #
  # This process tells the system which pieces of information,
  # like a name or email, are safe to save during registration.
  # It prevents hackers from sending hidden, malicious data.
  #
  # Attributes:: - *@sign_up* - the action of creating a new account.
  #              - *@account_update* - the action of changing profile details.
  #
  def configure_permitted_parameters

    # This adds the user's first and last name to the list
    # of allowed information when they first create an account.
    devise_parameter_sanitizer.permit(
      :sign_up,
      keys: %i[first_name last_name]
    )

    # This allows the user to safely update their first and
    # last name later on through their profile settings page.
    devise_parameter_sanitizer.permit(
      :account_update,
      keys: %i[first_name last_name]
    )
  end
end