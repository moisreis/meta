# app/queries/portfolios/recent_performance_query.rb
#
# Resolves the reference period and loads PerformanceHistory records for a
# portfolio. Falls back to the latest available period if the requested
# period has no data.
#
# @return [Array(Date, ActiveRecord::Relation<PerformanceHistory>)]
module Portfolios
  class RecentPerformanceQuery
    def self.call(portfolio, reference_date)
      new(portfolio, reference_date).call
    end

    def initialize(portfolio, reference_date)
      @portfolio      = portfolio
      @reference_date = reference_date
    end

    def call
      period      = @reference_date.end_of_month
      performance = load_for(period)
      return [period, performance] if performance.any?

      latest = @portfolio.performance_histories.maximum(:period)
      return [period, performance] unless latest

      [latest, load_for(latest)]
    end

    private

    def load_for(period)
      @portfolio.performance_histories
                .where(period: period)
                .includes(fund_investment: :investment_fund)
    end
  end
end