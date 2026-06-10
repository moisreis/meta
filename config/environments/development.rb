# frozen_string_literal: true

# config/environments/development.rb
#
# Configures the Rails application for the development environment.
#
# Enables code reloading, verbose logging, N+1 detection via Bullet,
# and local request handling for debugging. Production-safe behaviour
# such as eager loading or Solid Cache is not configured here.
#
# @author  Moisés Reis

require "active_support/core_ext/integer/time"

Rails.application.configure do

  # == N+1 Detection =========================================================

  config.after_initialize do
    Bullet.enable        = true
    Bullet.alert         = true
    Bullet.bullet_logger = true
    Bullet.console       = true
    Bullet.rails_logger  = true
    Bullet.add_footer    = true
  end


  # == Logging ================================================================

  config.rails_semantic_logger.started    = true
  config.rails_semantic_logger.processing = true
  config.rails_semantic_logger.rendered   = true

  # -- Level & Formatting -----------------------------------------------------

  config.logger                                = ActiveSupport::Logger.new($stdout)
  config.log_level                             = :debug
  config.active_support.deprecation            = :silence
  config.active_job.verbose_enqueue_logs       = true
  config.action_dispatch.verbose_redirect_logs = true


  # == General Settings =======================================================

  config.enable_reloading                                    = true
  config.eager_load                                          = false
  config.server_timing                                       = true
  config.consider_all_requests_local                         = true
  config.action_controller.raise_on_missing_callback_actions = true


  # == Caching ================================================================

  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching               = true
    config.action_controller.enable_fragment_cache_logging = true
    config.public_file_server.headers = {
      "cache-control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
  end

  config.cache_store = :memory_store


  # == Storage & Mailer =======================================================

  config.active_storage.service = :local

  # -- Mailer -----------------------------------------------------------------

  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching       = false
  config.action_mailer.default_url_options   = {
    host: "localhost",
    port: 3000
  }


  # == Database & Jobs ========================================================

  config.active_record.migration_error        = :page_load
  config.active_record.verbose_query_logs     = true
  config.active_record.query_log_tags_enabled = true


  # == Assets & Views =========================================================

  config.assets.quiet                                        = true
  config.action_view.annotate_rendered_view_with_filenames   = false

end