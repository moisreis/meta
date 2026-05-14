# frozen_string_literal: true

# Builds configuration options for pie chart rendering.
#
# This service provides a standardized configuration for pie/donut charts,
# typically used for proportional distribution visualization.
#
# @author Moisés Reis

module Charts

  # Constructs pie (donut) chart configuration options.
  class PieChartOptionsBuilder

    # ==========================================================================
    # PUBLIC METHODS
    # ==========================================================================

    # Builds a pie/donut chart configuration.
    #
    # @param data [Array] Dataset used for pie chart rendering. Expected to be
    #   in a format compatible with the charting library (e.g., label/value pairs).
    #
    # @return [Hash] Chart configuration object.
    def self.call(data)
      {
        data:   data,
        suffix: "%",
        donut:  true,
        legend: "left"
      }
    end
  end
end
