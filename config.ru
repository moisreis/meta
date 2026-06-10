# frozen_string_literal: true

# config.ru
#
# Rack entrypoint for the Rails application.
#
# Loads the Rails environment and exposes the application as a
# Rack-compatible endpoint for application servers.
#
# @author  Moisés Reis

# == Dependencies ============================================================

require_relative "config/environment"


# == Application =============================================================

run Rails.application


# == Server Initialization ===================================================

Rails.application.load_server