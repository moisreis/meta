# Configures the test environment for the Rails application.
#
# This environment is optimized for automated testing, prioritizing speed,
# isolation, and deterministic behavior. Data persistence is temporary and
# reset between test runs.
#
# @author Moisés Reis

Rails.application.configure do

  # ============================================================================
  # CODE LOADING & RELOADING
  # ============================================================================

  # Disable code reloading for faster test execution.
  config.enable_reloading = false

  # Enable eager loading only in CI environments to validate boot integrity.
  config.eager_load = ENV["CI"].present?

  # ============================================================================
  # FILE SERVER & CACHING
  # ============================================================================

  # Configure static file server headers for test performance.
  config.public_file_server.headers = {
    "cache-control" => "public, max-age=3600"
  }

  # Disable caching.
  config.cache_store = :null_store

  # ============================================================================
  # ERROR HANDLING
  # ============================================================================

  # Show full error reports.
  config.consider_all_requests_local = true

  # Render templates for known exceptions, raise others.
  config.action_dispatch.show_exceptions = :rescuable

  # ============================================================================
  # SECURITY SETTINGS
  # ============================================================================

  # Disable CSRF protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Raise error for invalid callback configurations.
  config.action_controller.raise_on_missing_callback_actions = true

  # ============================================================================
  # ACTIVE STORAGE
  # ============================================================================

  # Store uploads in a temporary test location.
  config.active_storage.service = :test

  # ============================================================================
  # ACTION MAILER
  # ============================================================================

  # Prevent real email delivery; store emails in memory.
  config.action_mailer.delivery_method = :test

  # Default host for URL generation in mailers.
  config.action_mailer.default_url_options = { host: "example.com" }

  # ============================================================================
  # LOGGING & DIAGNOSTICS
  # ============================================================================

  # Output deprecation warnings to stderr.
  config.active_support.deprecation = :stderr

end
