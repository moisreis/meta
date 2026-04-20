# Configures the Rails application and initializes framework-level settings.
#
# This file defines global configuration for the application, including
# framework loading, internationalization, error handling, asset paths,
# and autoload/eager load behavior.
#
# TABLE OF CONTENTS:
#
# 1. Boot & Framework Loading
# 2. Application Configuration
#   2a. Error Handling
#   2b. Assets
#   2c. Internationalization (I18n)
#   2d. Autoloading & Eager Loading
#   2e. Time Zone Configuration
#
# @author Moisés Reis

# =============================================================
#              1. BOOT & FRAMEWORK LOADING
# =============================================================

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile for the current environment.
Bundler.require(*Rails.groups)

module Meta
  # Main Rails application configuration class.
  #
  # Responsible for defining global behavior across all environments.
  #
  # @author Moisés Reis
  class Application < Rails::Application

    # =============================================================
    #                2a. ERROR HANDLING
    # =============================================================

    # Route all exceptions through Rails routing system.
    # Enables custom error pages via ErrorsController.
    config.exceptions_app = self.routes

    # =============================================================
    #                     2b. ASSETS
    # =============================================================

    # Enable asset pipeline and register custom asset paths.
    config.assets.enabled = true
    config.assets.paths << Rails.root.join("app", "assets", "fonts")

    # =============================================================
    #            2c. INTERNATIONALIZATION (I18N)
    # =============================================================

    # Set default locale and supported locales.
    config.i18n.default_locale = :'pt-BR'
    config.i18n.available_locales = [:'pt-BR', :en]

    # =============================================================
    #          2d. AUTOLOADING & EAGER LOADING
    # =============================================================

    # Autoload lib directory while ignoring non-Ruby subdirectories.
    config.autoload_lib(ignore: %w[assets tasks])

    # Add service objects to eager load paths.
    config.eager_load_paths << Rails.root.join("app/services")

    # =============================================================
    #              2e. TIME ZONE CONFIGURATION
    # =============================================================

    # Set application time zone and database timezone behavior.
    config.time_zone = "Brasilia"
    config.active_record.default_timezone = :local

    # =============================================================
    #              DEFAULT FRAMEWORK CONFIGURATION
    # =============================================================

    # Initialize configuration defaults for the target Rails version.
    config.load_defaults 8.1
  end
end
