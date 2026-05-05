# Defines application-wide constant values used across the system.
#
# This module centralizes static configuration values to avoid duplication
# and ensure consistency. It is intended to be referenced by views,
# services, and other layers that require globally consistent labels.
#
# TABLE OF CONTENTS:
#   1.  Company Identification
#
# @author Moisés Reis
module AppConstants
  # =============================================================
  #                  1. COMPANY IDENTIFICATION
  # =============================================================

  # Full legal name of the company used in formal documents and contracts.
  #
  # @return [String]
  COMPANY_NAME_LONG = "Meta Consultoria de Investimentos Institucionais Ltda".freeze

  # Shortened company name used in UI elements and informal contexts.
  #
  # @return [String]
  COMPANY_NAME_SHORT = "Meta Investimentos".freeze
end