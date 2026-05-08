# Builds a compliance report comparing actual allocation percentages against
# normative article constraints (minimum, maximum, and target values).
#
# This query object produces a normalized dataset used for reporting portfolio
# compliance status per normative article.
#
# @author Moisés Reis
module Portfolios
  class ComplianceReportQuery
    class << self

      # =============================================================
      #                      1. PUBLIC METHODS
      # =============================================================

      # Generates compliance report entries per normative article.
      #
      # @param portfolio [Portfolio] The portfolio being evaluated.
      # @param normative_data [Hash] Map of article_number => actual allocation value.
      #
      # @return [Array<Hash>] List of compliance records containing:
      #   :article [String]
      #   :actual  [Float]
      #   :min     [Float]
      #   :max     [Float]
      #   :target  [Float]
      #   :status  [String] ("success" or "danger")
      def call(portfolio, normative_data)
        portfolio.portfolio_normative_articles
                 .includes(:normative_article)
                 .map do |pna|
          actual = normative_data[pna.normative_article.article_number] || 0

          {
            article: pna.normative_article.article_number,
            actual:  actual.to_f,
            min:     pna.minimum_target.to_f,
            max:     pna.maximum_target.to_f,
            target:  pna.benchmark_target.to_f,
            status:  (actual >= pna.minimum_target && actual <= pna.maximum_target) ? "success" : "danger"
          }
        end
      end
    end
  end
end