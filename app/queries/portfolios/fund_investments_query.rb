# app/queries/portfolios/fund_investments_query.rb
# frozen_string_literal: true

module Portfolios
  ##
  # Retrieves optimized fund investments for portfolio views.
  # Filters by +active_for_period+ when a +reference_date+ is provided
  # so that stale fund investments are excluded from the current report.
  #
  class FundInvestmentsQuery
    class << self
      # @param portfolio [Portfolio]
      # @param reference_date [Date, nil] when given, only returns funds
      #   that had activity or value in that period.
      # @return [ActiveRecord::Relation<FundInvestment>]
      def call(portfolio, reference_date: nil)
        rel = portfolio.fund_investments.includes(:investment_fund)
        rel = rel.active_for_period(reference_date) if reference_date
        rel
      end
    end
  end
end