# Loads the Rails application and initializes it.
#
# This is the entry point that bootstraps the full Rails
# framework. It must be required before any application
# code runs.
#
# This file does not define application logic, routing,
# or configuration overrides.
#
# @author Moisés Reis

require_relative "application"

Rails.application.initialize!
