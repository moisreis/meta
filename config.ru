# Boots the Rails application through Rack and exposes it to the server interface.
#
# Rack configuration file used to initialize and start the Rails application.
# This file is responsible for loading the environment and executing the
# application entry point for Rack-based servers.
#
# TABLE OF CONTENTS:
#
# 1. Application Initialization
#
# @author Moisés Reis

# =============================================================
#                1. APPLICATION INITIALIZATION
# =============================================================

require_relative "config/environment"

run Rails.application
Rails.application.load_server
