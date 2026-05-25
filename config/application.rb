require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

# Application configuration for the Meta platform.
#
# Extends Rails::Application with custom autoload paths,
# locale settings, asset configuration, exception routing,
# and time zone defaults.
#
# Responsibilities:
# - Route exceptions through the application's error controller.
# - Enable the asset pipeline and include custom font paths.
# - Configure Brazilian Portuguese as the default locale.
# - Register custom autoload and eager load directories for
#   services, queries, concerns, forms, calculators, and builders.
# - Set the application time zone to Brasilia.
#
# This class does not define environment-specific behaviour.
# Environment overrides belong in config/environments/*.rb.
#
# @author Moisés Reis

module Meta
  class Application < Rails::Application

    # =============================================================
    #                         EXCEPTIONS
    # =============================================================

    config.exceptions_app = self.routes

    # =============================================================
    #                           ASSETS
    # =============================================================

    config.assets.enabled = true
    config.assets.paths << Rails.root.join("app", "assets", "fonts")

    # =============================================================
    #                    INTERNATIONALIZATION
    # =============================================================

    config.i18n.default_locale = :'pt-BR'
    config.i18n.available_locales = [:'pt-BR', :en]

    # =============================================================
    #                        AUTOLOAD PATHS
    # =============================================================

    config.autoload_lib(ignore: %w[assets tasks])

    # --- SERVICES ------------------------------------------------

    config.eager_load_paths << Rails.root.join("app/services")

    # --- QUERIES -------------------------------------------------

    config.autoload_paths << Rails.root.join("app/queries")
    config.eager_load_paths << Rails.root.join("app/queries")

    # --- COMPONENT CONCERNS --------------------------------------

    config.autoload_paths  << Rails.root.join("app/components/concerns")
    config.eager_load_paths << Rails.root.join("app/components/concerns")

    # --- FORM OBJECTS --------------------------------------------

    config.autoload_paths << Rails.root.join("app/forms")
    config.eager_load_paths << Rails.root.join("app/forms")

    # --- CALCULATORS ---------------------------------------------

    config.autoload_paths << Rails.root.join("app/calculators")
    config.eager_load_paths << Rails.root.join("app/calculators")

    # --- BUILDERS ------------------------------------------------

    config.autoload_paths << Rails.root.join("app/builders")
    config.eager_load_paths << Rails.root.join("app/builders")

    # =============================================================
    #                         TIME ZONE
    # =============================================================

    config.time_zone = "Brasilia"
    config.active_record.default_timezone = :local

    # =============================================================
    #                       RAILS DEFAULTS
    # =============================================================

    config.load_defaults 8.1
  end
end