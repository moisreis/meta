# frozen_string_literal: true

# app/lib/app_constants.rb
#
# Defines globally shared immutable application constants.
#
# Centralizes reusable UI labels, branding metadata, pagination defaults,
# and shared interface values used across views, components, and services.
#
# @author  Moisés Reis

module AppConstants

  # == Company Branding =======================================================

  # Full registered company name.
  #
  # @return [String]
  COMPANY_NAME_LONG = "Meta Consultoria de Investimentos Institucionais Ltda".freeze

  # Short display name used in UI contexts.
  #
  # @return [String]
  COMPANY_NAME_SHORT = "Meta Investimentos".freeze


  # == Pagination =============================================================

  # Default number of records displayed per paginated page.
  #
  # @return [Integer]
  INDEX_PER_PAGE = 14


  # == Shared Messages ========================================================

  # Fallback message displayed when no records or datasets are available.
  #
  # @return [String]
  NO_AVAILABLE_DATA_MESSAGE = "Nenhum dado disponível.".freeze


  # == Action Labels ==========================================================

  # -- Update -----------------------------------------------------------------

  # Default update button label.
  #
  # @return [String]
  UPDATE_BUTTON_LABEL = "Atualizar".freeze

  # Default update button icon identifier.
  #
  # @return [String]
  UPDATE_BUTTON_ICON = "refresh-cw".freeze

  # -- Create -----------------------------------------------------------------

  # Default create button label.
  #
  # @return [String]
  CREATE_BUTTON_LABEL = "Adicionar".freeze

  # Default create button icon identifier.
  #
  # @return [String]
  CREATE_BUTTON_ICON = "plus".freeze

end