# Defines the Continuous Integration (CI) pipeline for the Rails application.
#
# This file orchestrates setup, code quality checks, security audits,
# and automated test execution to ensure application integrity.
#
# TABLE OF CONTENTS:
#
# 1. Setup
# 2. Code Quality
# 3. Security Audits
# 4. Test Suite Execution
#
# @author Moisés Reis

# =============================================================
#                         1. SETUP
# =============================================================

CI.run do
  # Prepare the application environment without starting the server.
  step "Setup", "bin/setup --skip-server"

  # =============================================================
  #                     2. CODE QUALITY
  # =============================================================

  # Enforce Ruby style guidelines.
  step "Style: Ruby", "bin/rubocop"

  # =============================================================
  #                    3. SECURITY AUDITS
  # =============================================================

  # Check for vulnerable gem dependencies.
  step "Security: Gem audit", "bin/bundler-audit"

  # Audit JavaScript dependencies managed by Importmap.
  step "Security: Importmap vulnerability audit", "bin/importmap audit"

  # Static analysis for common Rails security issues.
  step "Security: Brakeman code analysis",
       "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  # =============================================================
  #                  4. TEST SUITE EXECUTION
  # =============================================================

  # Run unit and integration tests.
  step "Tests: Rails", "bin/rails test"

  # Run system/browser tests.
  step "Tests: System", "bin/rails test:system"

  # Validate seed data integrity in test environment.
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"
end
