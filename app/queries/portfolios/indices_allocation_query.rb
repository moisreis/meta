# app/queries/portfolios/indices_allocation_query.rb
#
# Returns allocation percentages grouped by benchmark index via a single
# aggregate SQL query.
module Portfolios
  class IndicesAllocationQuery
    def self.call(portfolio)
      portfolio.fund_investments
               .joins(:investment_fund)
               .group("investment_funds.benchmark_index")
               .sum(:percentage_allocation)
               .transform_keys { |key| key.presence || "Outros" }
    end
  end
end