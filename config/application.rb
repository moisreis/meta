# frozen_string_literal: true

# config/application.rb
#
# Application configuration for the Meta platform.
#
# Extends Rails::Application with custom autoload paths, locale settings,
# asset configuration, exception routing, and time zone defaults.
# Environment-specific overrides belong in config/environments/*.rb.
#
# @author  Moisés Reis

require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module Meta
  class Application < Rails::Application

    # == Exceptions ============================================================

    config.exceptions_app = self.routes


    # == Assets ================================================================

    config.assets.enabled = true
    config.assets.paths << Rails.root.join("app", "assets", "fonts")


    # == Internationalization ===================================================

    config.i18n.default_locale   = :'pt-BR'
    config.i18n.available_locales = [:'pt-BR', :en]


    # == Autoload Paths ========================================================

    config.autoload_lib(ignore: %w[assets tasks])

    # -- Services --------------------------------------------------------------

    config.eager_load_paths << Rails.root.join("app/services")

    # -- Queries ---------------------------------------------------------------

    config.autoload_paths  << Rails.root.join("app/queries")
    config.eager_load_paths << Rails.root.join("app/queries")

    # -- Component Concerns ----------------------------------------------------

    config.autoload_paths  << Rails.root.join("app/components/concerns")
    config.eager_load_paths << Rails.root.join("app/components/concerns")

    # -- Form Objects ----------------------------------------------------------

    config.autoload_paths  << Rails.root.join("app/forms")
    config.eager_load_paths << Rails.root.join("app/forms")

    # -- Calculators -----------------------------------------------------------

    config.autoload_paths  << Rails.root.join("app/calculators")
    config.eager_load_paths << Rails.root.join("app/calculators")

    # -- Builders --------------------------------------------------------------

    config.autoload_paths  << Rails.root.join("app/builders")
    config.eager_load_paths << Rails.root.join("app/builders")


    # == Time Zone =============================================================

    config.time_zone                     = "Brasilia"
    config.active_record.default_timezone = :local


    # == Rails Defaults ========================================================

    config.load_defaults 8.1

  end
end