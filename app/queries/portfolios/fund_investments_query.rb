# frozen_string_literal: true

# Retrieves optimized fund investments for portfolio views.
#
# Filters by +active_during+ when a +reference_date+ is provided
# so that stale fund investments are excluded from the current report.
#
# @author Moisés Reis

module Portfolios
  class FundInvestmentsQuery
    # @param portfolio [Portfolio]
    # @param reference_date [Date, nil] when given, only returns funds
    #   that had activity or value in that period.
    # @return [ActiveRecord::Relation<FundInvestment>]
    def self.call(portfolio, reference_date: nil)
      rel = portfolio.fund_investments.includes(:investment_fund)
      rel = rel.active_during(reference_date.beginning_of_month, reference_date) if reference_date
      rel
    end
  end
end
