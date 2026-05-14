# Boots the Rails application through the Rack interface.
#
# Rack configuration file responsible for loading the Rails environment and
# exposing the application object to Rack-compatible web servers such as Puma.
#
# @author Moisés Reis

# ============================================================================
# APPLICATION INITIALIZATION
# ============================================================================

require_relative "config/environment"

run Rails.application
Rails.application.load_server
