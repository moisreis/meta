# app/services/ui/trend_classifier.rb

# app/services/ui/trend_classifier.rb
#
# Ui namespace containing service objects responsible for UI-related logic.
#
# Determines trend direction from numeric input.
#
# @author Moisés Reis
module Ui
  # =============================================================
  #               Ui::TrendClassifier
  # =============================================================
  #
  # Encapsulates business logic for classifying numeric values into
  # UI-friendly trend indicators.
  #
  class TrendClassifier

    # =============================================================
    #                        1a. CALL
    # =============================================================

    # Determines the directional trend of a numeric value.
    #
    # @param value [Numeric, String, nil] Input value to classify.
    # @return [Symbol] One of :up, :down, or :stale.
    def call(value)
      numeric = value.to_f

      return :stale if numeric.zero?
      numeric.positive? ? :up : :down
    end
  end
end
