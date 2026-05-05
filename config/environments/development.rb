# Configures the development environment for the Rails application.
#
# This environment prioritizes developer productivity by enabling:
# - Automatic code reloading
# - Verbose debugging and query logging
# - Local file storage
# - Flexible caching behavior
# - Development diagnostics tooling
#
# @author Moisés Reis

require "active_support/core_ext/integer/time"

Rails.application.configure do

  # =============================================================
  #                  1. DEVELOPMENT TOOLING
  # =============================================================

  config.after_initialize do
    Bullet.enable        = true
    Bullet.alert         = true
    Bullet.bullet_logger = true
    Bullet.console       = true
    Bullet.rails_logger  = true
    Bullet.add_footer    = true
  end

  # =============================================================
  #             2. CODE LOADING & PERFORMANCE
  # =============================================================

  # Enable Semantic Logger lifecycle events.
  config.rails_semantic_logger.started    = true
  config.rails_semantic_logger.processing = true
  config.rails_semantic_logger.rendered   = true

  # Reload application code between requests.
  config.enable_reloading = true

  # Disable eager loading for faster boot time.
  config.eager_load = false

  # Enable browser timing metrics.
  config.server_timing = true

  # Show detailed exception pages.
  config.consider_all_requests_local = true

  # =============================================================
  #                        3. LOGGING
  # =============================================================

  # Log application output to STDOUT.
  config.logger = ActiveSupport::Logger.new($stdout)

  # Enable verbose logging.
  config.log_level = :debug

  # Silence framework deprecation warnings.
  config.active_support.deprecation = :silence

  # =============================================================
  #                         4. CACHING
  # =============================================================

  # Toggle caching using tmp/caching-dev.txt.
  if Rails.root.join("tmp/caching-dev.txt").exist?

    # Enable controller caching.
    config.action_controller.perform_caching = true

    # Enable fragment cache logging.
    config.action_controller.enable_fragment_cache_logging = true

    # Cache static assets for a short duration.
    config.public_file_server.headers = {
      "cache-control" => "public, max-age=#{2.days.to_i}"
    }

  else

    # Disable controller caching.
    config.action_controller.perform_caching = false

  end

  # Use in-memory cache storage.
  config.cache_store = :memory_store

  # =============================================================
  #                    5. ACTIVE STORAGE
  # =============================================================

  # Store uploaded files locally.
  config.active_storage.service = :local

  # =============================================================
  #                    6. ACTION MAILER
  # =============================================================

  # Do not raise delivery errors.
  config.action_mailer.raise_delivery_errors = false

  # Disable mailer caching.
  config.action_mailer.perform_caching = false

  # Configure mailer URL generation.
  config.action_mailer.default_url_options = {
    host: "localhost",
    port: 3000
  }

  # =============================================================
  #              7. ACTIVE RECORD & DEBUGGING
  # =============================================================

  # Raise an error when migrations are pending.
  config.active_record.migration_error = :page_load

  # Highlight query source locations.
  config.active_record.verbose_query_logs = true

  # Append metadata tags to SQL queries.
  config.active_record.query_log_tags_enabled = true

  # Highlight Active Job enqueue locations.
  config.active_job.verbose_enqueue_logs = true

  # Highlight redirect source locations.
  config.action_dispatch.verbose_redirect_logs = true

  # =============================================================
  #                   8. ASSETS & VIEWS
  # =============================================================

  # Suppress asset request logging.
  config.assets.quiet = true

  # Annotate rendered templates with file paths.
  config.action_view.annotate_rendered_view_with_filenames = true

  # =============================================================
  #          9. CONTROLLER & FRAMEWORK SAFETY
  # =============================================================

  # Raise errors for invalid callback references.
  config.action_controller.raise_on_missing_callback_actions = true

end