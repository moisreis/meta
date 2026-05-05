# app/queries/portfolios/allocation_data_query.rb
#
# Returns fund name + allocation percentage pairs for pie chart rendering.
# Accepts the already-loaded fund_investments relation to avoid a second query.
module Portfolios
  class AllocationDataQuery
    def self.call(fund_investments)
      fund_investments.map do |fi|
        [fi.investment_fund.fund_name, fi.percentage_allocation || 0]
      end
    end
  end
end