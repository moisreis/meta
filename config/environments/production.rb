# Configures the production environment for the Rails application.
#
# This environment prioritizes performance, security, and stability by enabling
# caching, eager loading, background processing, and optimized logging behavior.
#
# @author Moisés Reis

require "active_support/core_ext/integer/time"

Rails.application.configure do

  # =============================================================
  #           1. CODE LOADING & PERFORMANCE
  # =============================================================

  # Disable code reloading in production.
  config.enable_reloading = false

  # Eager load all application code on boot.
  config.eager_load = true

  # Disable full error reports.
  config.consider_all_requests_local = false

  # =============================================================
  #            2. CACHING & FILE SERVER
  # =============================================================

  # Enable controller-level caching.
  config.action_controller.perform_caching = true

  # Configure static file caching headers.
  config.public_file_server.headers = {
    "cache-control" => "public, max-age=#{1.year.to_i}"
  }

  # Use durable cache store.
  config.cache_store = :solid_cache_store

  # =============================================================
  #               3. ASSETS & STORAGE
  # =============================================================

  # Store uploaded files locally.
  config.active_storage.service = :local

  # =============================================================
  #                      4. LOGGING
  # =============================================================

  # Tag logs with request ID.
  config.log_tags = [:request_id]

  # Output logs to STDOUT.
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Log level (configurable via environment variable).
  # ENV:
  # - RAILS_LOG_LEVEL: [String] Log verbosity (default: "info").
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Silence health check endpoint logs.
  config.silence_healthcheck_path = "/up"

  # Disable deprecation reporting.
  config.active_support.report_deprecations = false

  # =============================================================
  #                 5. BACKGROUND JOBS
  # =============================================================

  # Use Solid Queue for background processing.
  config.active_job.queue_adapter = :solid_queue

  # Configure database connection for queue.
  config.solid_queue.connects_to = {
    database: { writing: :queue }
  }

  # =============================================================
  #                  6. ACTION MAILER
  # =============================================================

  # Default host for URL generation.
  config.action_mailer.default_url_options = { host: "example.com" }

  # =============================================================
  #           7. INTERNATIONALIZATION (I18N)
  # =============================================================

  # Enable locale fallbacks.
  config.i18n.fallbacks = true

  # =============================================================
  #                  8. ACTIVE RECORD
  # =============================================================

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Limit inspected attributes in logs.
  config.active_record.attributes_for_inspect = [:id]
end
