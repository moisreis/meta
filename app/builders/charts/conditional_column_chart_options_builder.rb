# Builds configuration options for conditional column charts with dynamic coloring
# based on positive or negative values.
#
# This query object centralizes chart styling rules and applies consistent
# color semantics for financial and performance visualizations.
#
# TABLE OF CONTENTS:
#   1. Constants & Configuration
#   2. Public Methods
#   3. Private Methods
#
# @author Moisés Reis
module Charts
  class ConditionalColumnChartOptionsBuilder

    # =============================================================
    #                 1. CONSTANTS & CONFIGURATION
    # =============================================================

    POSITIVE_COLOR = ChartPalettes.rgba(:green, 0.85)
    NEGATIVE_COLOR = ChartPalettes.rgba(:red, 0.85)

    private_constant :POSITIVE_COLOR,
                     :NEGATIVE_COLOR

    # =============================================================
    #                      2. PUBLIC METHODS
    # =============================================================

    # Builds chart configuration with conditional bar colors.
    #
    # @param data [Array<Array, Numeric>] Dataset used to derive bar colors.
    # @param overrides [Hash] Optional configuration overrides applied via deep_merge.
    #
    # @return [Hash] Final chart configuration for rendering.
    def self.call(data, **overrides)
      {
        prefix: "R$ ",
        thousands: ".",
        decimal: ",",
        library: {
          plugins: {
            colorschemes: false
          },
          elements: {
            bar: {
              borderWidth: 0
            }
          }
        },
        dataset: {
          borderWidth: 0,
          backgroundColor: background_colors(data)
        }
      }.deep_merge(overrides)
    end

    # =============================================================
    #                      3. PRIVATE METHODS
    # =============================================================

    # Derives background colors based on value sign.
    #
    # @param data [Enumerable] Collection of [key, value] pairs.
    #
    # @return [Array<String>] Array of RGBA color strings.
    def self.background_colors(data)
      data.map do |_, value|
        value.to_f >= 0 ? POSITIVE_COLOR : NEGATIVE_COLOR
      end
    end

    private_class_method :background_colors
  end
end