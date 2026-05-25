# frozen_string_literal: true

# Defines the CI pipeline execution flow for automated verification.
#
# This configuration is executed by the CI runner and orchestrates
# all validation steps required before code is accepted into the
# main branch.
#
# Responsibilities:
# - Define deterministic setup of the application environment.
# - Execute code style validation (RuboCop).
# - Run dependency and application security audits.
# - Execute automated test suites (unit, system, and seed validation).
#
# This file does NOT:
# - Configure CI infrastructure (runners, caching, parallelism).
# - Define deployment workflows.
#
# @author Moisés Reis

# =============================================================
#                          PIPELINE
# =============================================================

CI.run do

  # --- ENVIRONMENT SETUP --------------------------------------

  # Prepares the application environment for CI execution.
  #
  # @return [void]
  step "Setup", "bin/setup --skip-server"

  # --- CODE STYLE ---------------------------------------------

  # Enforces Ruby style consistency using RuboCop.
  #
  # @return [void]
  step "Style: Ruby", "bin/rubocop"

  # --- SECURITY AUDITS ----------------------------------------

  # Audits installed gems for known vulnerabilities.
  #
  # @return [void]
  step "Security: Gem audit", "bin/bundler-audit"

  # Audits Importmap dependencies for vulnerabilities.
  #
  # @return [void]
  step "Security: Importmap vulnerability audit", "bin/importmap audit"

  # Static security analysis of Rails application codebase.
  #
  # @return [void]
  step "Security: Brakeman code analysis",
       "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  # --- TEST SUITES --------------------------------------------

  # Executes Rails unit and integration tests.
  #
  # @return [void]
  step "Tests: Rails", "bin/rails test"

  # Executes system tests (browser-level integration tests).
  #
  # @return [void]
  step "Tests: System", "bin/rails test:system"

  # Re-seeds and validates database seed consistency in test environment.
  #
  # @return [void]
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"
end