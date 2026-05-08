# Calculates deviation between portfolio benchmark targets and normative article benchmark targets.
#
# This query object compares portfolio-level benchmark allocations against reference
# normative articles and returns per-record deviations where both values are present.
#
# @author Moisés Reis
module Portfolios
  class BenchmarkDeviationQuery
    class << self

      # =============================================================
      #                      1. PUBLIC METHODS
      # =============================================================

      # Computes deviation between portfolio benchmark targets and normative references.
      #
      # @param portfolio [Portfolio] The portfolio containing normative article mappings.
      #
      # @return [Hash{Integer => BigDecimal, nil}] Map of portfolio_normative_article_id
      #   to deviation value, or nil when data is incomplete.
      def call(portfolio)
        portfolio
          .portfolio_normative_articles
          .includes(:normative_article)
          .each_with_object({}) do |pna, hash|
            benchmark_target = pna.benchmark_target
            reference_target = pna.normative_article&.benchmark_target

            hash[pna.id] =
              if benchmark_target.present? && reference_target.present?
                benchmark_target - reference_target
              else
                nil
              end
          end
      end
    end
  end
end