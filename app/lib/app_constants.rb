# Defines application-wide immutable constants shared across the system.
#
# This module centralizes static business and interface constants used by
# multiple application layers to avoid duplication and maintain consistency.
#
# @author Moisés Reis
module AppConstants

  # ==========================================================================
  # COMPANY INFORMATION
  # ==========================================================================

  # Official registered company name used in legal and formal contexts.
  #
  # @return [String] Immutable full company name.
  COMPANY_NAME_LONG = "Meta Consultoria de Investimentos Institucionais Ltda".freeze

  # Shortened company name used in interfaces and general presentation contexts.
  #
  # @return [String] Immutable abbreviated company name.
  COMPANY_NAME_SHORT = "Meta Investimentos".freeze

  # ==========================================================================
  # PAGINATION SETTINGS
  # ==========================================================================

  # Default number of records displayed per paginated index page.
  #
  # @return [Integer] Immutable pagination size used across index views.
  INDEX_PER_PAGE = 14

  # ==========================================================================
  # DEFAULT MESSAGES
  # ==========================================================================

  # Message displayed when no data is available to present in a view.
  #
  # @return [String] Immutable default message for empty datasets.
  NO_AVAILABLE_DATA_MESSAGE = "Nenhum dado disponível.".freeze
end
