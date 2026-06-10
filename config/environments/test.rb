# frozen_string_literal: true

# config/environments/test.rb
#
# Configures Rails test environment behavior.
#
# Defines caching strategy, error handling, asset behavior,
# and test-specific defaults for mailer and storage.
#
# @author  Moisés Reis

Rails.application.configure do

  # == General Settings ======================================================

  config.enable_reloading = false
  config.eager_load = ENV["CI"].present?

  config.consider_all_requests_local = true
  config.action_dispatch.show_exceptions = :rescuable

  config.action_controller.allow_forgery_protection = false
  config.action_controller.raise_on_missing_callback_actions = true

  config.active_support.deprecation = :stderr


  # == Caching & Storage =====================================================

  config.public_file_server.headers = {
    "cache-control" => "public, max-age=3600"
  }

  config.cache_store = :null_store

  config.active_storage.service = :test


  # == Mailer ================================================================

  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = { host: "example.com" }

end