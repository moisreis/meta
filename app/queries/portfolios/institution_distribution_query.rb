# institution_distribution_query.rb
module Portfolios
  class InstitutionDistributionQuery
    def self.call(portfolio)
      portfolio.fund_investments
               .includes(:investment_fund)
               .group_by { |fi| fi.investment_fund.administrator_name }
               .map { |admin, investments| [admin, investments.sum { |fi| fi.percentage_allocation || 0 }] }
    end
  end
end