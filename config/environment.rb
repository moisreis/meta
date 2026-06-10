# frozen_string_literal: true

# config/environment.rb
#
# Entry point that bootstraps the full Rails framework.
#
# Loads the application and initializes it. Must be required before any
# application code runs. Does not define logic, routing, or configuration.
#
# @author  Moisés Reis

require_relative "application"

Rails.application.initialize!