# frozen_string_literal: true

# app/calculators/portfolios/yearly_return_calculator.rb
#
# Calculates the year-to-date portfolio return, weighted by each
# fund investment's percentage allocation.
#
module Portfolios
  class YearlyReturnCalculator

    ZERO = BigDecimal("0")

    # @param portfolio [Portfolio]
    # @param reference_date [Date, nil]
    # @return [BigDecimal]
    def self.call(portfolio, reference_date: nil)
      new(portfolio, reference_date: reference_date).call
    end

    # @param portfolio [Portfolio]
    # @param reference_date [Date, nil]
    def initialize(portfolio, reference_date: nil)
      @portfolio      = portfolio
      @reference_date = reference_date
    end

    # @return [BigDecimal]
    def call
      return ZERO unless target_period
      return ZERO if performances.empty?

      weighted    = ZERO
      total_alloc = ZERO

      performances.group_by(&:fund_investment_id).each do |_, fund_perfs|
        fi    = fund_perfs.first.fund_investment
        alloc = fi.percentage_allocation.to_d
        accumulated = fund_perfs.sum { |p| p.monthly_return.to_d }

        weighted    += accumulated * alloc
        total_alloc += alloc
      end

      total_alloc > 0 ? weighted / total_alloc : ZERO
    end

    private

    attr_reader :portfolio, :reference_date

    # @return [Date, nil]
    def target_period
      @target_period ||= reference_date ||
                         portfolio.performance_histories.maximum(:period)
    end

    # @return [ActiveRecord::Relation]
    def performances
      @performances ||= portfolio
                          .performance_histories
                          .where(period: target_period.beginning_of_year..target_period)
                          .includes(:fund_investment)
    end
  end
end
