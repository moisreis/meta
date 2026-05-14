# frozen_string_literal: true

# Builds configuration options for line series chart rendering.
#
# This service generates a standardized configuration for multi-series line
# charts, typically used for trend analysis and percentage-based comparisons.
#
# @author Moisés Reis

module Charts

  # Constructs line series chart configuration options.
  class LineSeriesChartOptionsBuilder

    # ==========================================================================
    # INITIALIZATION
    # ==========================================================================

    # Creates an instance and builds chart options in one call.
    #
    # @param data [Enumerable] Dataset used for chart rendering.
    # @return [Hash] Chart configuration object.
    def self.call(data)
      new(data).call
    end

    # Initializes the builder with dataset input.
    #
    # @param data [Enumerable] Dataset used for chart rendering.
    def initialize(data)
      @data = data
    end

    # ==========================================================================
    # PUBLIC METHODS
    # ==========================================================================

    # Builds the final line series chart configuration.
    #
    # @return [Hash] Chart configuration object including library options
    #   and color definitions.
    def call
      {
        colors: ChartPalettes.css(:line_series),
        library: base_library_options
      }
    end

    private

    # ==========================================================================
    # PRIVATE METHODS
    # ==========================================================================

    # Returns base configuration for the underlying charting library.
    #
    # @return [Hash] Library-specific configuration options.
    def base_library_options
      {
        curveType: "function",
        legend: { position: "bottom" },
        hAxis: { textPosition: "out" },
        vAxis: { format: "percent" },
        focusTarget: "category"
      }
    end
  end
end
