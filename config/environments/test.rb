# Configures the Rails application for the test environment.
#
# Disables code reloading, uses a null cache store, and
# sets up test-friendly defaults for mailer and storage.
#
# This file does not configure development logging features
# or production caching strategies.
#
# @author Moisés Reis

Rails.application.configure do

  # =============================================================
  #                      GENERAL SETTINGS
  # =============================================================

  config.enable_reloading = false
  config.eager_load = ENV["CI"].present?

  config.consider_all_requests_local = true
  config.action_dispatch.show_exceptions = :rescuable

  config.action_controller.allow_forgery_protection = false
  config.action_controller.raise_on_missing_callback_actions = true

  config.active_support.deprecation = :stderr

  # =============================================================
  #                      CACHING & STORAGE
  # =============================================================

  config.public_file_server.headers = {
    "cache-control" => "public, max-age=3600"
  }

  config.cache_store = :null_store

  config.active_storage.service = :test

  # =============================================================
  #                          MAILER
  # =============================================================

  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = { host: "example.com" }
end