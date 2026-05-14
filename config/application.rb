# Configures the Rails application and initializes framework-level settings.
#
# This file defines global configuration for the application, including
# framework loading, internationalization, error handling, asset paths,
# and autoload/eager load behavior.
#
# @author Moisés Reis

# =============================================================
# BOOT & FRAMEWORK LOADING
# =============================================================

require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module Meta

  # Main Rails application configuration class.
  #
  # Responsible for defining global behavior across all environments.
  #
  # @author Moisés Reis
  class Application < Rails::Application

    # =============================================================
    # ERROR HANDLING
    # =============================================================

    config.exceptions_app = self.routes

    # =============================================================
    # ASSETS
    # =============================================================

    config.assets.enabled = true
    config.assets.paths << Rails.root.join("app", "assets", "fonts")

    # =============================================================
    # INTERNATIONALIZATION (I18N)
    # =============================================================

    config.i18n.default_locale = :'pt-BR'
    config.i18n.available_locales = [:'pt-BR', :en]

    # =============================================================
    # AUTOLOADING & EAGER LOADING
    # =============================================================

    config.autoload_lib(ignore: %w[assets tasks])

    config.eager_load_paths << Rails.root.join("app/services")

    config.autoload_paths << Rails.root.join("app/queries")
    config.eager_load_paths << Rails.root.join("app/queries")

    config.autoload_paths << Rails.root.join("app/forms")
    config.eager_load_paths << Rails.root.join("app/forms")

    config.autoload_paths << Rails.root.join("app/calculators")
    config.eager_load_paths << Rails.root.join("app/calculators")

    config.autoload_paths << Rails.root.join("app/builders")
    config.eager_load_paths << Rails.root.join("app/builders")

    # =============================================================
    # TIME ZONE CONFIGURATION
    # =============================================================

    config.time_zone = "Brasilia"
    config.active_record.default_timezone = :local

    # =============================================================
    # FRAMEWORK DEFAULTS
    # =============================================================

    config.load_defaults 8.1
  end
end
