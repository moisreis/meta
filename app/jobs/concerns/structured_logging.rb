# frozen_string_literal: true

# Concern responsible for providing standardized JSON logging capabilities to
# background jobs and service objects.
#
# This module ensures that logs follow a consistent structure, facilitating
# better observability and easier parsing in log management platforms.
#
# @author Moisés Reis

module StructuredLogging

  # ==========================================================================
  # LOGGING METHODS
  # ==========================================================================

  # Emits an INFO level log entry in JSON format.
  #
  # @param message [String] The primary log message.
  # @param metadata [Hash] Additional context to be merged into the JSON payload.
  # @return [void]
  def log_info(message, metadata = {})
    Rails.logger.info({ job: self.class.name, message: message, **metadata }.to_json)
  end

  # Emits an ERROR level log entry in JSON format.
  #
  # @param message [String] The primary error message.
  # @param metadata [Hash] Additional context to be merged into the JSON payload.
  # @return [void]
  def log_error(message, metadata = {})
    Rails.logger.error({ job: self.class.name, message: message, **metadata }.to_json)
  end
end
