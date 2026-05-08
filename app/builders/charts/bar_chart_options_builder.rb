# Builds configuration options for bar chart rendering.
#
# This query object provides a default chart configuration and allows
# selective overrides for customization of visualization behavior.
#
# @author Moisés Reis
module Charts
  class BarChartOptionsBuilder
    class << self

      # =============================================================
      #                      1. PUBLIC METHODS
      # =============================================================

      # Builds a merged configuration hash for bar chart rendering.
      #
      # @param overrides [Hash] Optional configuration overrides applied via deep_merge.
      #
      # @return [Hash] Final chart configuration including defaults and overrides.
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