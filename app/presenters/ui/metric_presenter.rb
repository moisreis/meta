# frozen_string_literal: true

# app/presenters/ui/metric_presenter.rb
#
# Ui namespace containing presenters responsible for standardized UI metric rendering.
#
# Handles percentage formatting and trend classification logic.
#
# @author Moisés Reis
module Ui
  # =============================================================
  #                 Ui::MetricPresenter
  # =============================================================
  #
  # Provides formatting and classification utilities for numeric metrics
  # displayed in UI components such as dashboards and tables.
  #
  class MetricPresenter < BasePresenter

    # =============================================================
    #                      1a. PERCENTAGE RENDERING
    # =============================================================

    # Formats a numeric value as a percentage string.
    #
    # @param value [Numeric, nil] The numeric value to format.
    # @param precision [Integer] Number of decimal places to truncate to.
    # @return [String] Formatted percentage string or "-" if blank.
    def percentage(value, precision: 2)
      return "-" if value.blank?

      formatted = h.number_to_percentage(
        value.to_d.truncate(precision),
        precision: precision,
        separator: ",",
        delimiter: "."
      )

      formatted
    end

    # =============================================================
    #                      1b. TREND CLASSIFICATION
    # =============================================================

    # Classifies a numeric value into a directional trend indicator.
    #
    # @param value [Numeric, nil] The value to evaluate.
    # @param format [Symbol] Unused placeholder for compatibility (:currency expected).
    # @return [Symbol, String] :up, :down, :stale, or "-" if blank.
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
