# frozen_string_literal: true

# Calculates the year-to-date portfolio return, weighted by each
# fund investment's percentage allocation.
#
# Aggregates monthly returns across all fund investments and weights
# them by their respective allocation percentage to produce a single
# portfolio-level YTD return.
#
# @author Moisés Reis

module Portfolios
  class YearlyReturnCalculator

    ZERO = BigDecimal("0")

    private_constant :ZERO

    # =============================================================
    #                         PUBLIC METHODS
    # =============================================================

    # Shortcut class method to instantiate and execute the calculator.
    #
    # @param portfolio [Portfolio] The portfolio being evaluated.
    # @param reference_date [Date, nil] Reference date for the YTD window.
    #   Defaults to the latest available performance period.
    # @return [BigDecimal] The weighted YTD return percentage.
    def self.call(portfolio, reference_date: nil)
      new(portfolio, reference_date: reference_date).call
    end

    # =============================================================
    #                         INITIALIZATION
    # =============================================================

    # Initialises the calculator with portfolio and optional reference date.
    #
    # @param portfolio [Portfolio] The portfolio being evaluated.
    # @param reference_date [Date, nil] Reference date for the YTD window.
    def initialize(portfolio, reference_date: nil)
      @portfolio      = portfolio
      @reference_date = reference_date
    end

    # =============================================================
    #                         PUBLIC METHODS
    # =============================================================

    # Calculates the weighted YTD return.
    #
    # @return [BigDecimal] The weighted YTD return percentage.
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

    # =============================================================
    #                          ATTRIBUTES
    # =============================================================

    attr_reader :portfolio, :reference_date

    # =============================================================
    #                     INTERMEDIATE DATA
    # =============================================================

    # Returns the target period date for the YTD calculation.
    #
    # @return [Date, nil]
    def target_period
      @target_period ||= reference_date ||
                         portfolio.performance_histories.maximum(:period)
    end

    # Returns performance histories within the YTD window.
    #
    # @return [ActiveRecord::Relation<PerformanceHistory>]
    def performances
      @performances ||= portfolio
                          .performance_histories
                          .where(period: target_period.beginning_of_year..target_period)
                          .includes(:fund_investment)
    end
  end
end
