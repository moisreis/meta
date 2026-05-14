# frozen_string_literal: true

# Provides UI presentation helpers and reusable rendering abstractions.
#
# This namespace groups presenter objects responsible for encapsulating
# reusable view rendering logic and presentation-specific formatting behavior.
#
# @author Moisés Reis

module Ui

  # Renders derived metric and trend-related presentation values.
  #
  # This presenter provides lightweight formatting helpers for:
  # - percentages
  # - trend classifications
  #
  # Unlike other presenters in this namespace, this object primarily
  # returns primitive presentation values rather than rendered HTML.
  class MetricPresenter < BasePresenter

    # ==========================================================================
    # PUBLIC METHODS
    # ==========================================================================

    # Formats a numeric value as a percentage string.
    #
    # Values are truncated to the specified precision before formatting.
    #
    # @param value [Numeric, nil] Numeric percentage value to format.
    # @param precision [Integer] Decimal precision used for truncation and formatting.
    # @return [String] Formatted percentage string or fallback placeholder.
    def percentage(value, precision: 2)
      return "-" if value.blank?

      h.number_to_percentage(
        value.to_d.truncate(precision),
        precision: precision,
        separator: ",",
        delimiter: "."
      )
    end

    # Classifies a numeric value into a directional trend state.
    #
    # Supported trend states:
    # - :up
    # - :down
    # - :stale
    #
    # @param value [Numeric, nil] Numeric value evaluated for trend direction.
    # @param format [Symbol] Reserved formatting context parameter.
    # @return [Symbol, String] Trend classification or fallback placeholder.
    def trend(value, format: :currency)
      return "-" if value.blank?

      if value.positive?
        :up
      elsif value.negative?
        :down
      else
        :stale
      end
    end
  end
end
