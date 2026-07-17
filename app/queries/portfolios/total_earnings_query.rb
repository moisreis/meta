# frozen_string_literal: true

# Calculates the total earnings for a portfolio in a specific reference
# period.
#
# @author Moisés Reis

module Portfolios
  class TotalEarningsQuery

    # @param portfolio [Portfolio]
    # @param reference_date [Date]
    def initialize(portfolio, reference_date)
      @portfolio = portfolio
      @reference_date = reference_date
    end

    # @return [BigDecimal]
    def call
      recent_performance.sum { |perf| perf.earnings.to_f }
    end

    # @param portfolio [Portfolio]
    # @param reference_date [Date]
    #
    # @return [BigDecimal]
    def self.call(portfolio, reference_date)
      new(portfolio, reference_date).call
    end

    private

    # Reuses the same source used by the dashboard's fund table
    # (Portfolios::ShowService#performance_fields), so totals always
    # match what's shown per fund.
    #
    # @return [ActiveRecord::Relation]
    def recent_performance
      Portfolios::RecentPerformanceQuery.call(@portfolio, @reference_date).last
    end
  end
end