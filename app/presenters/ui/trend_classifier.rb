# frozen_string_literal: true

# Classifies numeric values into directional trend states.
#
# This service object converts numeric values into semantic trend
# classifications used by UI presentation components.
#
# Supported trend states:
# - :up
# - :down
# - :stale
#
# @author Moisés Reis

module Ui
  class TrendClassifier

    # =============================================================
    #                        PUBLIC METHODS
    # =============================================================

    # Resolves the directional trend classification for a numeric value.
    #
    # Values equal to zero are considered stable.
    #
    # @param value [Numeric, #to_f] Numeric value evaluated for trend direction.
    # @return [Symbol] Trend classification identifier.
    def call(value)
      numeric = value.to_f

      return :stale if numeric.zero?

      numeric.positive? ? :up : :down
    end
  end
end
