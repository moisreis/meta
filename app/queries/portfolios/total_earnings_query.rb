# frozen_string_literal: true

module Portfolios
  ##
  # Calculates the total earnings for a portfolio
  # in a specific reference period.
  #
  class TotalEarningsQuery
    ##
    # @param portfolio [Portfolio]
    # @param reference_date [Date]
    #
    def initialize(portfolio, reference_date)
      @portfolio = portfolio
      @reference_date = reference_date
    end

    ##
    # @return [BigDecimal]
    #
    def call
      portfolio.performance_histories
               .where(period: target_period)
               .sum(:earnings)
    end

    ##
    # @param portfolio [Portfolio]
    # @param reference_date [Date]
    #
    # @return [BigDecimal]
    #
    def self.call(portfolio, reference_date)
      new(portfolio, reference_date).call
    end

    private

    attr_reader :portfolio, :reference_date

    ##
    # @return [Date]
    #
    def target_period
      reference_date.to_date.end_of_month
    end
  end
end