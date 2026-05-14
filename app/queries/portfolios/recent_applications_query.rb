# frozen_string_literal: true

module Portfolios
  class RecentApplicationsQuery

    LIMIT = 5

    def self.call(portfolio, year: Date.current.year)
      new(portfolio, year).call
    end

    def initialize(portfolio, year)
      @portfolio = portfolio
      @year      = year
    end

    def call
      Application
        .joins(:fund_investment)
        .where(fund_investments: { portfolio_id: @portfolio.id })
        .where(request_date: year_range)
        .includes(fund_investment: :investment_fund)
        .order(request_date: :desc)
        .limit(LIMIT)
    end

    private

    def year_range
      Date.new(@year).beginning_of_year..Date.new(@year).end_of_year
    end

  end
end