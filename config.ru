# frozen_string_literal: true

# Rack-compatible entrypoint for the Rails application.
#
# This file defines how the Rails application is mounted and
# executed by Rack-based application servers (e.g., Puma).
#
# @author Moisés Reis

# =============================================================
#                        ENVIRONMENT BOOT
# =============================================================

# Loads the full Rails environment, including initializers,
# application configuration, and dependencies.
#
# @return [void]
require_relative "config/environment"

# =============================================================
#                        APPLICATION RUN
# =============================================================

# Exposes the Rails application as a Rack-compatible endpoint.
#
# @return [Rails::Application]
run Rails.application

# =============================================================
#                      SERVER INITIALIZATION
# =============================================================

# Executes server-specific initialization hooks if defined.
#
# This is typically used by alternative server adapters to
# perform additional boot-time configuration.
#
# @return [void]
Rails.application.load_server