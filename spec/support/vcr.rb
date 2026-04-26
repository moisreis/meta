# Configures VCR for recording and replaying HTTP interactions during tests.
#
# This setup integrates VCR with WebMock and RSpec, enabling deterministic
# tests by persisting external HTTP responses as cassette files.
#
# TABLE OF CONTENTS:
#   1.  Cassette Storage Configuration
#   2.  HTTP Hook Integration
#   3.  RSpec Metadata Integration
#   4.  Sensitive Data Filtering
#   5.  Default Cassette Options
#
# @author Moisés Reis

# =============================================================
#              1. CASSETTE STORAGE CONFIGURATION
# =============================================================

VCR.configure do |config|
  # Defines the directory where cassette files are stored.
  config.cassette_library_dir = 'spec/cassettes'

  # =============================================================
  #                 2. HTTP HOOK INTEGRATION
  # =============================================================

  # Hooks VCR into WebMock to intercept HTTP requests.
  config.hook_into :webmock

  # =============================================================
  #              3. RSpec METADATA INTEGRATION
  # =============================================================

  # Enables automatic cassette usage via RSpec metadata (`:vcr`).
  #
  # Example:
  #   it "fetches data", :vcr do
  #     ...
  #   end
  config.configure_rspec_metadata!

  # =============================================================
  #               4. SENSITIVE DATA FILTERING
  # =============================================================

  # Replaces occurrences of sensitive host data in recorded cassettes.
  #
  # @param interaction [VCR::HTTPInteraction] The HTTP interaction being recorded.
  # @return [String] The filtered value to be substituted in the cassette.
  config.filter_sensitive_data('<CVM_HOST>') { 'cvmweb.cvm.gov.br' }

  # =============================================================
  #              5. DEFAULT CASSETTE OPTIONS
  # =============================================================

  # Sets default behavior for cassette recording.
  #
  # Options:
  # - :new_episodes → records new HTTP interactions while preserving existing ones.
  #
  # @return [Hash] Default cassette configuration options.
  config.default_cassette_options = { record: :new_episodes }
end
