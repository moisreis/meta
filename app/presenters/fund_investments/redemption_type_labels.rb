# frozen_string_literal: true

# Provides localized presentation labels for
# fund investment redemption types.
#
# This module centralizes redemption type label formatting
# to ensure consistency across views, presenters, services,
# and reports by mapping type identifiers to display labels,
# providing safe fallback humanization, and standardizing
# redemption terminology.
#
# This module does NOT perform persistence, validation,
# or business-rule enforcement.
#
# @author Moisés Reis

module FundInvestments
  module RedemptionTypeLabels
    extend self

    # =============================================================
    #                 CONSTANTS & CONFIGURATION
    # =============================================================

    # Maps redemption type identifiers to
    # localized presentation labels.
    #
    # @return [Hash<String, String>]
    LABELS = {
      "partial" => "Parcial",
      "total" => "Total",
      "emergency" => "Emergencial",
      "scheduled" => "Agendado"
    }.freeze

    # =============================================================
    #                      PUBLIC INTERFACE
    # =============================================================

    # Returns the localized label for a redemption type.
    #
    # Unknown values fallback to Rails humanized formatting.
    #
    # @param redemption_type [String, Symbol]
    #   Redemption type identifier.
    #
    # @return [String]
    #   Localized redemption type label.
    def call(redemption_type)
      LABELS.fetch(
        redemption_type.to_s,
        redemption_type.to_s.humanize
      )
    end
  end
end