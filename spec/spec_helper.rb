# Configures RSpec expectations, mocking behavior, and shared context handling.
#
# This block defines how RSpec evaluates expectations, validates mocks, and
# applies shared context metadata across example groups. It enforces stricter
# test correctness and clearer failure messages.
#
# TABLE OF CONTENTS:
#   1.  Expectations Configuration
#   2.  Mocking Configuration
#   3.  Shared Context Behavior
#
# @author Moisés Reis

# =============================================================
#                 1. EXPECTATIONS CONFIGURATION
# =============================================================

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    # Includes chained clauses in custom matcher descriptions.
    #
    # Example:
    #   expect(user).to be_valid.and have_attributes(name: "John")
    #
    # @return [Boolean] Always true when enabled.
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # =============================================================
  #                   2. MOCKING CONFIGURATION
  # =============================================================

  config.mock_with :rspec do |mocks|
    # Verifies that partial doubles reference real methods on objects.
    #
    # Prevents stubbing or mocking non-existent methods, reducing false positives.
    #
    # @return [Boolean] Always true when enabled.
    mocks.verify_partial_doubles = true
  end

  # =============================================================
  #                 3. SHARED CONTEXT BEHAVIOR
  # =============================================================

  # Applies shared context metadata to host groups automatically.
  #
  # Ensures metadata defined in shared contexts propagates correctly when included.
  #
  # @return [Symbol] The configured behavior (:apply_to_host_groups).
  config.shared_context_metadata_behavior = :apply_to_host_groups
end
