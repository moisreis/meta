# frozen_string_literal: true

module Portfolios
  ##
  # Calculates the accumulated yearly earnings for a portfolio.
  #
  class YearlyEarningsQuery
    ##
    # @param portfolio [Portfolio]
    # @param reference_date [Date]
    #
    def initialize(portfolio, reference_date = Date.current)
      @portfolio = portfolio
      @reference_date = reference_date
    end

    ##
    # @return [Float]
    #
    def call
      performance_scope.sum(:earnings).to_f
    end

    private

    attr_reader :portfolio, :reference_date

    ##
    # @return [ActiveRecord::Relation]
    #
    def performance_scope
      portfolio.performance_histories.where(
        period: beginning_of_year..end_of_month
      )
    end

    ##
    # @return [Date]
    #
    def beginning_of_year
      reference_date.beginning_of_year
    end

    ##
    # @return [Date]
    #
    def end_of_month
      reference_date.end_of_month
    end
  end
end