# frozen_string_literal: true

# Computes the cumulative portfolio equity evolution timeline
# based on monthly applications and redemptions.
#
# Returns an array of [month_label, cumulative_value] pairs suitable
# for chart rendering and historical reporting.
#
# @author Moisés Reis

module Portfolios
  class ValueTimelineCalculator

    ZERO = BigDecimal("0")

    private_constant :ZERO

    # =============================================================
    #                         PUBLIC METHODS
    # =============================================================

    # Shortcut class method to instantiate and execute the calculator.
    #
    # @param portfolio [Portfolio] The portfolio being evaluated.
    # @param months_back [Integer] Number of trailing months to return.
    # @return [Array<Array(String, BigDecimal)>] Timeline series.
    def self.call(portfolio, months_back: 12)
      new(portfolio, months_back).call
    end

    # =============================================================
    #                         INITIALIZATION
    # =============================================================

    # Initialises the calculator with portfolio and lookback window.
    #
    # @param portfolio [Portfolio] The portfolio being evaluated.
    # @param months_back [Integer] Number of trailing months to return.
    def initialize(portfolio, months_back)
      @portfolio   = portfolio
      @months_back = months_back
    end

    # =============================================================
    #                         PUBLIC METHODS
    # =============================================================

    # Builds the cumulative equity timeline.
    #
    # @return [Array<Array(String, BigDecimal)>] Timeline series.
    def call
      running_total = ZERO

      timeline = all_months.map do |month|
        running_total += applications_total_for(month)
        running_total -= redemptions_total_for(month)

        [
          month.strftime("%b/%y"),
          running_total
        ]
      end

      timeline.last(@months_back)
    end

    private

    # =============================================================
    #                      CASH FLOW DATA
    # =============================================================

    # Returns application totals grouped by month.
    #
    # @return [Hash<Date, BigDecimal>]
    def applications_by_month
      @applications_by_month ||= Application
                                   .joins(:fund_investment)
                                   .where(
                                     fund_investments: {
                                       portfolio_id: @portfolio.id
                                     }
                                   )
                                   .where.not(cotization_date: nil)
                                   .group("DATE_TRUNC('month', cotization_date)")
                                   .sum(:financial_value)
    end

    # Returns redemption totals grouped by month.
    #
    # @return [Hash<Date, BigDecimal>]
    def redemptions_by_month
      @redemptions_by_month ||= Redemption
                                  .joins(:fund_investment)
                                  .where(
                                    fund_investments: {
                                      portfolio_id: @portfolio.id
                                    }
                                  )
                                  .where.not(cotization_date: nil)
                                  .group("DATE_TRUNC('month', cotization_date)")
                                  .sum(:redeemed_liquid_value)
    end

    # =============================================================
    #                        MONTH HELPERS
    # =============================================================

    # Returns all unique months sorted chronologically.
    #
    # @return [Array<Date>]
    def all_months
      @all_months ||= (
        applications_by_month.keys +
        redemptions_by_month.keys
      ).uniq.sort
    end

    # Returns the total applications value for a given month.
    #
    # @param month [Date] Target month.
    # @return [BigDecimal]
    def applications_total_for(month)
      BigDecimal(
        (applications_by_month[month] || 0).to_s
      )
    end

    # Returns the total redemptions value for a given month.
    #
    # @param month [Date] Target month.
    # @return [BigDecimal]
    def redemptions_total_for(month)
      BigDecimal(
        (redemptions_by_month[month] || 0).to_s
      )
    end
  end
end