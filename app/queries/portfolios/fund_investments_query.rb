# app/queries/portfolios/fund_investments_query.rb
# frozen_string_literal: true

module Portfolios
  ##
  # Retrieves optimized fund investments for portfolio views.
  #
  class FundInvestmentsQuery
    class << self
      # @param portfolio [Portfolio]
      # @return [ActiveRecord::Relation<FundInvestment>]
      def call(portfolio)
        portfolio.fund_investments.includes(:investment_fund)
      end
    end
  end
end