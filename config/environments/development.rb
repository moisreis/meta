# Configures the development environment for the Rails application.
#
# This environment prioritizes developer productivity by enabling code reloading,
# verbose logging, debugging tools, and flexible caching behavior.
#
# TABLE OF CONTENTS:
#
# 1. Code Loading & Performance
# 2. Logging
# 3. Caching
# 4. Active Storage
# 5. Action Mailer
# 6. Active Record & Debugging
# 7. Assets & Views
# 8. Controller & Framework Safety
#
# @author Moisés Reis

require "active_support/core_ext/integer/time"

Rails.application.configure do

  # =============================================================
  #           1. CODE LOADING & PERFORMANCE
  # =============================================================

  # Enable code reloading without server restart.
  config.enable_reloading = true

  # Disable eager loading for faster boot.
  config.eager_load = false

  # Enable server timing metrics.
  config.server_timing = true

  # Show full error reports.
  config.consider_all_requests_local = false

  # =============================================================
  #                      2. LOGGING
  # =============================================================

  # Enable Lograge for structured logging.
  config.lograge.enabled = true

  # Log to STDOUT.
  config.logger = ActiveSupport::Logger.new($stdout)

  # Debug-level logging.
  config.log_level = :debug

  # Silence deprecation warnings.
  config.active_support.deprecation = :silence

  # =============================================================
  #                       3. CACHING
  # =============================================================

  # Toggle caching via tmp/caching-dev.txt.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    # Cache static files for short duration in development.
    config.public_file_server.headers = {
      "cache-control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
  end

  # Use in-memory cache store.
  config.cache_store = :memory_store

  # =============================================================
  #                    4. ACTIVE STORAGE
  # =============================================================

  # Store uploads locally.
  config.active_storage.service = :local

  # =============================================================
  #                    5. ACTION MAILER
  # =============================================================

  # Do not raise errors if mail delivery fails.
  config.action_mailer.raise_delivery_errors = false

  # Disable mailer caching.
  config.action_mailer.perform_caching = false

  # Default URL options for mailer links.
  config.action_mailer.default_url_options = {
    host: "localhost",
    port: 3000
  }

  # =============================================================
  #         6. ACTIVE RECORD & DEBUGGING
  # =============================================================

  # Raise error if migrations are pending.
  config.active_record.migration_error = :page_load

  # Highlight query origins in logs.
  config.active_record.verbose_query_logs = true

  # Append metadata to SQL queries.
  config.active_record.query_log_tags_enabled = true

  # Highlight job enqueue origins.
  config.active_job.verbose_enqueue_logs = true

  # Highlight redirect origins.
  config.action_dispatch.verbose_redirect_logs = true

  # =============================================================
  #                7. ASSETS & VIEWS
  # =============================================================

  # Suppress asset request logs.
  config.assets.quiet = true

  # Annotate rendered views with file names.
  config.action_view.annotate_rendered_view_with_filenames = true

  # =============================================================
  #        8. CONTROLLER & FRAMEWORK SAFETY
  # =============================================================

  # Raise error for invalid callback configurations.
  config.action_controller.raise_on_missing_callback_actions = true
end
