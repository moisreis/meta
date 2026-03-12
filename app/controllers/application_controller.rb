# === application_controller.rb
#
# Description:: This file acts as the foundation for all other controllers
#               within the application, holding shared logic and security
#               rules that apply to every part of the web interface.
#
# Usage:: - *What* - A central command center that defines how the website
#           behaves for every visitor and logged-in user.
#         - *How* - It uses built-in +Rails+ tools to check browser
#           versions and manage user permissions automatically.
#         - *Why* - Keeping these rules here ensures the website stays
#           secure and consistent without repeating code elsewhere.
#
# Attributes:: - *@allow_browser* [Method] - Limits access to modern browsers
#                to ensure a secure and updated user experience.
#              - *@stale_when_importmap_changes* [Method] - Updates assets
#                automatically when the application's code is refreshed.
#              - *@configure_permitted_parameters* [Method] - Handles user
#                data security for registration and profile updates.
#
# View:: - +ApplicationView+
#
# Notes:: References to other files, controllers, or classes should be written
#         using +Devise+ or +ActionController+ so they are highlighted in RDoc.

# =============================================================
#                        Core Controller
# =============================================================
# This class serves as the parent for all controllers in the app,
# providing a shared space for security settings and behavior
# that every page on the website must follow to work correctly.

class ApplicationController < ActionController::Base

  # This line ensures the website only works on updated and
  # secure web browsers to protect the user's information.
  # It prevents older, vulnerable software from connecting.
  allow_browser versions: :modern

  # This command tells the browser to download the latest
  # styles and scripts whenever the app receives an update.
  # It keeps the interface looking fresh and working perfectly.
  stale_when_importmap_changes

  # This instruction checks if a user is trying to sign in
  # or sign up before allowing certain data to be saved.
  # It connects the security rules to the +Devise+ system.
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # =============================================================
  #                       Private Helpers
  # =============================================================

  # == configure_permitted_parameters
  #
  # @author Moisés Reis
  #
  # This process tells the system which pieces of information,
  # like a name or email, are safe to save during registration.
  # It prevents hackers from sending hidden, malicious data.
  #
  # Attributes:: - *keys* - The specific pieces of user data allowed.
  #              - *sign_up* - The event of creating a new account.
  #
  # Returns:: - A list of approved data fields for the user profile.

  def configure_permitted_parameters

    # This adds the user's first and last name to the list
    # of allowed information when they first create an account.
    # It ensures the system recognizes their identity correctly.
    devise_parameter_sanitizer.permit(
      :sign_up,
      keys: %i[first_name last_name]
    )

    # This allows the user to safely update their first and
    # last name later on through their profile settings page.
    # It keeps the personal information accurate and current.
    devise_parameter_sanitizer.permit(
      :account_update,
      keys: %i[first_name last_name]
    )
  end
end