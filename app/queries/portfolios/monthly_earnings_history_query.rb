# frozen_string_literal: true

# Groups performance earnings by month for a given year.
#
# @author Moisés Reis

module Portfolios
  class MonthlyEarningsHistoryQuery
    # @param portfolio [Portfolio]
    # @param year [Integer] defaults to current year
    # @return [Hash<Date, BigDecimal>]
    def self.call(portfolio, year: Date.current.year)
      range = Date.new(year).beginning_of_year..Date.new(year).end_of_year

      portfolio.performance_histories
               .where(period: range)
               .group_by { |ph| ph.period.beginning_of_month }
               .transform_values { |records| records.sum(&:earnings) }
    end
  end
end
