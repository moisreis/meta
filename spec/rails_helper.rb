# Configures the RSpec test environment, coverage reporting, and test isolation
# strategies for the application.
#
# This file initializes core testing tools including RSpec, SimpleCov for code
# coverage, WebMock for HTTP stubbing, and DatabaseCleaner for database state
# management. It defines global behavior applied across the entire test suite.
#
# TABLE OF CONTENTS:
#   1.  Environment Setup
#   2.  Coverage Configuration
#   3.  RSpec Configuration
#       3a. Global Includes
#       3b. Database Cleaning Strategy
#       3c. HTTP Stubbing (WebMock)
#       3d. RSpec Defaults
#   4.  Shoulda Matchers Configuration
#
# @author Moisés Reis

# =============================================================
#                       1. ENVIRONMENT SETUP
# =============================================================

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rspec/rails'
require 'simplecov'
require 'webmock/rspec'
require 'database_cleaner/active_record'

# =============================================================
#                    2. COVERAGE CONFIGURATION
# =============================================================

# Initializes SimpleCov to measure test coverage across the Rails application.
#
# Filters:
# - /spec/: Excludes test files from coverage metrics.
# - /config/: Excludes configuration files.
#
# Enforces a minimum coverage threshold of 80%.
SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  minimum_coverage 80
end

# =============================================================
#                     3. RSpec CONFIGURATION
# =============================================================

RSpec.configure do |config|
  # =============================================================
  #                      3a. GLOBAL INCLUDES
  # =============================================================

  # Includes FactoryBot syntax methods (e.g., `create`, `build`).
  config.include FactoryBot::Syntax::Methods

  # Includes time helpers such as `travel_to` for time-based testing.
  config.include ActiveSupport::Testing::TimeHelpers

  # =============================================================
  #               3b. DATABASE CLEANING STRATEGY
  # =============================================================

  # Configures DatabaseCleaner before the entire test suite runs.
  #
  # Strategy:
  # - Default: :transaction (fast, rollback-based)
  # - Initial cleanup: :truncation (ensures clean baseline)
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  # Wraps each example with the appropriate cleaning strategy.
  #
  # @param example [RSpec::Core::Example] The current test example.
  #
  # Behavior:
  # - Uses :transaction by default.
  # - Switches to :truncation when metadata `:truncation` is present
  #   (required for tests involving `after_commit` or external threads).
  #
  # @return [void]
  config.around(:each) do |example|
    strategy = example.metadata[:truncation] ? :truncation : :transaction
    DatabaseCleaner.strategy = strategy
    DatabaseCleaner.cleaning { example.run }
  end

  # =============================================================
  #                3c. HTTP STUBBING (WEBMOCK)
  # =============================================================

  # Disables all external HTTP connections during tests.
  #
  # Allows localhost connections to support tools such as Capybara.
  #
  # @return [void]
  config.before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  # =============================================================
  #                      3d. RSpec DEFAULTS
  # =============================================================

  # Infers spec types (e.g., controller, model) from file location.
  config.infer_spec_type_from_file_location!

  # Cleans Rails-related backtrace noise for readability.
  config.filter_rails_from_backtrace!
end

# =============================================================
#             4. SHOULDA MATCHERS CONFIGURATION
# =============================================================

# Configures Shoulda Matchers to integrate with RSpec and Rails.
#
# @return [void]
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
