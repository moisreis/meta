# frozen_string_literal: true

# Builds configuration options for bar chart rendering.
#
# This service provides a standardized baseline configuration for charting
# components and allows controlled overrides through deep merging.
#
# @author Moisés Reis

module Charts

  # Constructs Chart.js-compatible bar chart configuration options.
  class BarChartOptionsBuilder

    # ==========================================================================
    # PUBLIC METHODS
    # ==========================================================================

    class << self

      # Builds a bar chart configuration hash with optional overrides.
      #
      # The returned configuration is compatible with Chart.js-style libraries
      # and includes sensible defaults for legends, dataset styling, and suffix formatting.
      #
      # @param overrides [Hash] Optional configuration overrides.
      #   These values are deeply merged into the base configuration.
      # @return [Hash] Final chart configuration object.
      def call(**overrides)
        {
          suffix: "%",
          library: {
            plugins: {
              legend: {
                position: "bottom"
              }
            }
          },
          dataset: {
            borderWidth: 0
          }
        }.deep_merge(overrides)
      end
    end
  end
end
