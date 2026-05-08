# Builds standardized configuration for pie and donut charts.
#
# This builder defines consistent formatting rules for circular charts,
# including percentage suffixing and default legend positioning.
#
# TABLE OF CONTENTS:
#   1. Public Methods
#
# @author Moisés Reis
module Charts
  class PieChartOptionsBuilder
    class << self

      # =============================================================
      #                      1. PUBLIC METHODS
      # =============================================================

      # Builds the configuration hash for pie/donut chart rendering.
      #
      # @param data [Array<Hash>] Dataset used for pie chart visualization.
      #
      # @return [Hash] Chart configuration options.
      def call(data)
        {
          data:    data,
          suffix:  "%",
          donut:   true,
          legend:  "left"
        }
      end
    end
  end
end