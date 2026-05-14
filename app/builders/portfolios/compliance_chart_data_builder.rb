# frozen_string_literal: true

# Builds chart-ready datasets for portfolio compliance visualization.
#
# This service transforms compliance report data into a structured format
# suitable for charting libraries, mapping portfolio compliance metrics
# into labeled series.
#
# @author Moisés Reis

module Portfolios

  # Constructs compliance chart data series from a report dataset.
  #
  # Each series corresponds to a compliance dimension (actual, target, max)
  # and is transformed into a chart-compatible structure.
  class ComplianceChartDataBuilder

    # ==========================================================================
    # CONSTANTS
    # ==========================================================================

    SERIES = {
      actual: "Alocação Atual",
      target: "Objetivo",
      max:    "Limite Máximo"
    }.freeze

    private_constant :SERIES

    # ==========================================================================
    # PUBLIC METHODS
    # ==========================================================================

    # Builds chart-ready series data from a compliance report.
    #
    # @param report [Enumerable<Hash>] Collection of compliance rows.
    #   Each row must include:
    #   - :article [String] article identifier
    #   - :actual [Numeric]
    #   - :target [Numeric]
    #   - :max [Numeric]
    #
    # @return [Array<Hash>] Chart series structure compatible with frontend charting.
    def self.call(report)
      SERIES.map do |key, label|
        {
          name: label,
          data: report.map do |row|
            [row[:article], row[key]]
          end
        }
      end
    end
  end
end
