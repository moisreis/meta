# frozen_string_literal: true

# Builds configuration options for conditional column chart rendering.
#
# This service generates Chart.js-compatible configuration with conditional
# dataset coloring based on value polarity (positive/negative).
#
# It centralizes UI styling rules for financial bar/column visualizations.
#
# @author Moisés Reis

module Charts

  # Constructs a column chart configuration with conditional coloring rules.
  class ConditionalColumnChartOptionsBuilder

    # ==========================================================================
    # CONSTANTS
    # ==========================================================================

    POSITIVE_COLOR = ChartPalettes.rgba(:green, 0.85)
    NEGATIVE_COLOR = ChartPalettes.rgba(:red, 0.85)

    private_constant :POSITIVE_COLOR, :NEGATIVE_COLOR

    # ==========================================================================
    # PUBLIC METHODS
    # ==========================================================================

    # Builds a conditional column chart configuration.
    #
    # Each dataset value is evaluated to determine its background color:
    # - >= 0 → POSITIVE_COLOR
    # - < 0  → NEGATIVE_COLOR
    #
    # @param data [Enumerable<Array>] Dataset in the form of [label, value] pairs.
    # @param overrides [Hash] Optional Chart.js configuration overrides.
    # @return [Hash] Final chart configuration object.
    def self.call(data, **overrides)
      {
        prefix: "R$ ",
        thousands: ".",
        decimal: ",",
        library: {
          plugins: { colorschemes: false },
          elements: { bar: { borderWidth: 0 } }
        },
        dataset: {
          borderWidth: 0,
          backgroundColor: background_colors(data)
        }
      }.deep_merge(overrides)
    end

    # ==========================================================================
    # PRIVATE METHODS
    # ==========================================================================

    # Generates an array of background colors based on value polarity.
    #
    # @param data [Enumerable<Array>] Dataset containing [key, value] pairs.
    # @return [Array<String>] Color values aligned with dataset ordering.
    def self.background_colors(data)
      data.map { |_, value| value.to_f >= 0 ? POSITIVE_COLOR : NEGATIVE_COLOR }
    end

    private_class_method :background_colors
  end
end
