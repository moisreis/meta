# Configures Devise authentication for the application.
#
# Sets the mailer sender, ORM adapter, and all auth behaviour
# flags — password policy, session storage, confirmation,
# reset timeouts, navigation formats, and HTTP response codes.
#
# This file does not define routes, controllers, or views.
# Those belong in config/routes.rb and the Devise views folder.
#
# @author Moisés Reis

Devise.setup do |config|

  # --- MAILER SENDER -------------------------------------------

  config.mailer_sender = 'please-change-me-at-config-initializers-devise@example.com'

  # --- ORM ------------------------------------------------------

  require 'devise/orm/active_record'

  # --- AUTHENTICATION BEHAVIOUR --------------------------------

  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]

  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = true
  config.expire_all_remember_me_on_sign_out = true

  # --- PASSWORD POLICY -----------------------------------------

  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours

  # --- NAVIGATION & RESPONSE -----------------------------------

  config.navigational_formats = ['*/*', :html, :turbo_stream]
  config.sign_out_via = :delete

  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other
end