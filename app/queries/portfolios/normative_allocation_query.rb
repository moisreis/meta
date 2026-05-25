# frozen_string_literal: true

# Returns allocation percentages grouped by normative article number via a
# single aggregate SQL query.
#
# @author Moisés Reis

module Portfolios
  class NormativeAllocationQuery
    # @param portfolio [Portfolio]
    # @return [Hash{String => Numeric}]
    def self.call(portfolio)
      portfolio.fund_investments
               .joins(investment_fund: :normative_articles)
               .group("normative_articles.article_number")
               .sum(:percentage_allocation)
               .transform_keys { |key| key.presence || "Não enquadrado" }
    end
  end
end
