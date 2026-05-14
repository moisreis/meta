# Boots and initializes the Rails application environment.
#
# This file loads the application configuration and triggers the
# initialization process required to prepare the framework for execution.
#
# @author Moisés Reis

# ============================================================================
# APPLICATION BOOT & INITIALIZATION
# ============================================================================

# Load the Rails application configuration.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!
