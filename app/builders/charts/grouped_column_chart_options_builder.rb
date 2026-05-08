# Builds standardized configuration for grouped column charts.
#
# This builder encapsulates chart formatting rules for grouped datasets,
# enforcing consistent numeric formatting and color palettes across charts.
#
# TABLE OF CONTENTS:
#   1. Public Methods
#
# @author Moisés Reis
module Charts
  class GroupedColumnChartOptionsBuilder
    class << self

      # =============================================================
      #                      1. PUBLIC METHODS
      # =============================================================

      # Builds the configuration hash for grouped column chart rendering.
      #
      # @param data [Array<Hash>] Dataset used for grouped visualization.
      #
      # @return [Hash] Chart configuration options.
      def call(data)
        {
          data:      data,
          stacked:   false,
          prefix:    "R$ ",
          thousands: ".",
          decimal:   ",",
          colors:    [
            ChartPalettes.rgba(:green, 0.85),
            ChartPalettes.rgba(:red, 0.85)
          ],
          dataset:   {
            borderWidth: 0
          }
        }
      end
    end
  end
end