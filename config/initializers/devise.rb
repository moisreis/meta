# Configures Devise authentication settings for the Rails application.
#
# This initializer defines authentication behavior, security policies,
# email handling, password rules, and response formats used by Devise.
#
# TABLE OF CONTENTS:
#
# 1. Mailer Configuration
# 2. ORM & Authentication Keys
# 3. Session & Security Settings
# 4. Password & Recovery
# 5. Navigation & Response Behavior
#
# @author Moisés Reis

Devise.setup do |config|

  # =============================================================
  #                  1. MAILER CONFIGURATION
  # =============================================================

  # Default sender email for Devise mailers.
  config.mailer_sender = 'please-change-me-at-config-initializers-devise@example.com'

  # =============================================================
  #            2. ORM & AUTHENTICATION KEYS
  # =============================================================

  # Use ActiveRecord as ORM.
  require 'devise/orm/active_record'

  # Normalize authentication keys.
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]

  # =============================================================
  #           3. SESSION & SECURITY SETTINGS
  # =============================================================

  # Skip session storage for HTTP authentication.
  config.skip_session_storage = [:http_auth]

  # BCrypt cost factor (lower in test for speed).
  config.stretches = Rails.env.test? ? 1 : 12

  # Require email reconfirmation on change.
  config.reconfirmable = true

  # Invalidate remember-me tokens on logout.
  config.expire_all_remember_me_on_sign_out = true

  # =============================================================
  #               4. PASSWORD & RECOVERY
  # =============================================================

  # Allowed password length range.
  config.password_length = 6..128

  # Email validation regex.
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # Password reset token validity window.
  config.reset_password_within = 6.hours

  # =============================================================
  #         5. NAVIGATION & RESPONSE BEHAVIOR
  # =============================================================

  # Formats considered navigational (used by Devise redirects).
  config.navigational_formats = ['*/*', :html, :turbo_stream]

  # HTTP method used for sign out.
  config.sign_out_via = :delete

  # Response status codes for Turbo compatibility.
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other
end
