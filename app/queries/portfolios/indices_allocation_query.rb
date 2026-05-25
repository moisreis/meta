# frozen_string_literal: true

# Returns allocation percentages grouped by benchmark index via a single
# aggregate SQL query.
#
# @author Moisés Reis

module Portfolios
  class IndicesAllocationQuery
    # @param portfolio [Portfolio]
    # @return [Hash{String => Numeric}]
    def self.call(portfolio)
      portfolio.fund_investments
               .joins(:investment_fund)
               .group("investment_funds.benchmark_index")
               .sum(:percentage_allocation)
               .transform_keys { |key| key.presence || "Outros" }
    end
  end
end
