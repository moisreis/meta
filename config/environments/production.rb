# frozen_string_literal: true

# config/environments/production.rb
#
# Configures the Rails application for the production environment.
#
# Enables eager loading, Solid Cache, Solid Queue, and production-safe
# settings for performance and reliability. Development-only features
# such as N+1 detection or verbose query logs are not configured here.
#
# @author  Moisés Reis

require "active_support/core_ext/integer/time"

Rails.application.configure do

  # == General Settings =======================================================

  config.enable_reloading                    = false
  config.eager_load                          = true
  config.consider_all_requests_local         = false
  config.silence_healthcheck_path            = "/up"
  config.active_support.report_deprecations  = false


  # == Caching & Storage ======================================================

  config.action_controller.perform_caching = true

  config.public_file_server.headers = {
    "cache-control" => "public, max-age=#{1.year.to_i}"
  }

  # -- Cache Store ------------------------------------------------------------

  config.cache_store = :solid_cache_store

  # -- Active Storage ---------------------------------------------------------

  config.active_storage.service = :local


  # == Logging ================================================================

  config.log_tags  = [:request_id]
  config.logger    = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")


  # == Job Queue ==============================================================

  config.active_job.queue_adapter = :solid_queue

  config.solid_queue.connects_to = {
    database: { writing: :queue }
  }


  # == Mailer & Internationalization ==========================================

  # -- Mailer -----------------------------------------------------------------

  config.action_mailer.default_url_options = { host: "example.com" }

  # -- I18n -------------------------------------------------------------------

  config.i18n.fallbacks = true


  # == Active Record ==========================================================

  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect      = [:id]

end