# app/queries/portfolios/institution_distribution_query.rb
#
# Returns administrator name + allocation percentage pairs grouped by institution.
# Accepts the already-loaded fund_investments relation to avoid a second query.
module Portfolios
  class InstitutionDistributionQuery
    def self.call(fund_investments)
      fund_investments
        .group_by { |fi| fi.investment_fund.administrator_name }
        .map { |admin, investments| [admin, investments.sum { |fi| fi.percentage_allocation || 0 }] }
    end
  end
end