# frozen_string_literal: true

# Builds chart-ready datasets for monthly portfolio earnings visualization.
#
# This service transforms a sparse dataset of monthly earnings into a
# normalized 12-month series suitable for time-series chart rendering.
#
# Missing months are explicitly filled with zero values to ensure chart
# continuity and consistent axis representation.
#
# @author Moisés Reis

module Portfolios

  # Constructs a normalized monthly earnings dataset for chart rendering.
  class MonthlyEarningsChartDataBuilder

    # ==========================================================================
    # PUBLIC METHODS
    # ==========================================================================

    # Builds a 12-month time-series dataset for a given year.
    #
    # @param data [Hash{Date => Numeric}] Mapping of month start dates to earnings values.
    # @param year [Integer] Target year used to generate the monthly timeline.
    # @return [Array<Array(String, Numeric)>] Chart-ready dataset in the format:
    #   [ "Jan/26", 1000 ], [ "Feb/26", 1200 ], ...
    def self.call(data, year: Date.current.year)
      months = (1..12).map { |m| Date.new(year, m, 1) }

      months.map do |month|
        [
          month.strftime("%b/%y"),
          data[month] || 0
        ]
      end
    end
  end
end
