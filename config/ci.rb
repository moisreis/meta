# frozen_string_literal: true

# ci.rb
#
# Defines the CI pipeline execution flow for automated verification.
#
# Orchestrates all validation steps required before code is accepted
# into the main branch. Executed by the CI runner in the order defined.
#
# @author  Moisés Reis

CI.run do

  # == Environment Setup ======================================================

  # Prepares the application environment for CI execution.
  step "Setup", "bin/setup --skip-server"


  # == Code Style =============================================================

  # Enforces Ruby style consistency using RuboCop.
  step "Style: Ruby", "bin/rubocop"


  # == Security ===============================================================

  # -- Gem Audit --------------------------------------------------------------

  # Audits installed gems for known vulnerabilities.
  step "Security: Gem audit", "bin/bundler-audit"

  # -- Importmap --------------------------------------------------------------

  # Audits Importmap dependencies for known vulnerabilities.
  step "Security: Importmap vulnerability audit", "bin/importmap audit"

  # -- Brakeman ---------------------------------------------------------------

  # Static security analysis of the Rails application codebase.
  step "Security: Brakeman code analysis",
       "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"


  # == Test Suites ============================================================

  # -- Rails ------------------------------------------------------------------

  # Executes unit and integration tests.
  step "Tests: Rails", "bin/rails test"

  # -- System -----------------------------------------------------------------

  # Executes browser-level integration tests.
  step "Tests: System", "bin/rails test:system"

  # -- Seeds ------------------------------------------------------------------

  # Re-seeds and validates database seed consistency in the test environment.
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

end