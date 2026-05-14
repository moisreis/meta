# Configures Devise authentication settings for the Rails application.
#
# This initializer defines authentication behavior, security policies,
# email handling, password rules, and response formats used by Devise.
#
# @author Moisés Reis

Devise.setup do |config|

  # =============================================================
  # MAILER CONFIGURATION
  # =============================================================

  config.mailer_sender = 'please-change-me-at-config-initializers-devise@example.com'

  # =============================================================
  # ORM & AUTHENTICATION KEYS
  # =============================================================

  require 'devise/orm/active_record'

  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]

  # =============================================================
  # SESSION & SECURITY SETTINGS
  # =============================================================

  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = true
  config.expire_all_remember_me_on_sign_out = true

  # =============================================================
  # PASSWORD & RECOVERY
  # =============================================================

  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours

  # =============================================================
  # NAVIGATION & RESPONSE BEHAVIOR
  # =============================================================

  config.navigational_formats = ['*/*', :html, :turbo_stream]
  config.sign_out_via = :delete

  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other
end
