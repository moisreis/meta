# frozen_string_literal: true

# Retrieves the most recent redemptions for a portfolio within a given year.
#
# @author Moisés Reis

module Portfolios
  class RecentRedemptionsQuery

    LIMIT = 5

    # @param portfolio [Portfolio]
    # @param year [Integer] defaults to current year
    # @return [ActiveRecord::Relation<Redemption>]
    def self.call(portfolio, year: Date.current.year)
      new(portfolio, year).call
    end

    def initialize(portfolio, year)
      @portfolio = portfolio
      @year      = year
    end

    def call
      Redemption
        .joins(:fund_investment)
        .where(fund_investments: { portfolio_id: @portfolio.id })
        .where(request_date: year_range)
        .includes(fund_investment: :investment_fund)
        .order(request_date: :desc)
        .limit(LIMIT)
    end

    private

    def year_range
      Date.new(@year, 1, 1).all_year
    end

  end
end
