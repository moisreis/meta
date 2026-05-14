# frozen_string_literal: true

# Builds configuration options for grouped column chart rendering.
#
# This service provides a standardized chart configuration for grouped
# (non-stacked) column visualizations, typically used for comparative
# financial datasets.
#
# @author Moisés Reis

module Charts

  # Constructs grouped column chart configuration options.
  class GroupedColumnChartOptionsBuilder

    # ==========================================================================
    # PUBLIC METHODS
    # ==========================================================================

    # Builds a grouped column chart configuration.
    #
    # The configuration is intended for multi-series column charts where
    # datasets are displayed side-by-side rather than stacked.
    #
    # @param data [Array] Chart data structure compatible with the target
    #   charting library.
    #
    # @return [Hash] Chart configuration object including formatting,
    #   color palette, and dataset options.
    def self.call(data)
      {
        data:      data,
        stacked:   false,
        prefix:    "R$ ",
        thousands: ".",
        decimal:   ",",
        colors: [
          ChartPalettes.rgba(:green, 0.85),
          ChartPalettes.rgba(:red, 0.85)
        ],
        dataset: { borderWidth: 0 }
      }
    end
  end
end
