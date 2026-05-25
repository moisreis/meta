# frozen_string_literal: true

# Groups allocation percentages by fund administrator.
#
# @author Moisés Reis

module Portfolios
  class InstitutionDistributionQuery
    # @param portfolio [Portfolio]
    # @return [Array<Array(String, Numeric)>]
    def self.call(portfolio)
      portfolio.fund_investments
               .includes(:investment_fund)
               .group_by { |fi| fi.investment_fund.administrator_name }
               .map { |admin, investments| [admin, investments.sum { |fi| fi.percentage_allocation || 0 }] }
    end
  end
end
