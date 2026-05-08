# app/calculators/portfolios/value_timeline_calculator.rb
#
# Computes the cumulative portfolio equity evolution timeline
# based on monthly applications and redemptions.
#
# Returns an array suitable for charts and reporting:
#
# [
#   ["Jan/26", 100000.0],
#   ["Feb/26", 125000.0]
# ]
#
module Portfolios
  class ValueTimelineCalculator
    ZERO = BigDecimal("0")

    private_constant :ZERO

    # @param portfolio [Portfolio]
    # @param months_back [Integer]
    # @return [Array<Array(String, BigDecimal)>]
    def self.call(portfolio, months_back: 12)
      new(portfolio, months_back).call
    end

    # @param portfolio [Portfolio]
    # @param months_back [Integer]
    def initialize(portfolio, months_back)
      @portfolio   = portfolio
      @months_back = months_back
    end

    # @return [Array<Array(String, BigDecimal)>]
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

    # @return [Hash]
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

    # @return [Hash]
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

    # @return [Array<Date>]
    def all_months
      @all_months ||= (
        applications_by_month.keys +
        redemptions_by_month.keys
      ).uniq.sort
    end

    # @param month [Date]
    # @return [BigDecimal]
    def applications_total_for(month)
      BigDecimal(
        (applications_by_month[month] || 0).to_s
      )
    end

    # @param month [Date]
    # @return [BigDecimal]
    def redemptions_total_for(month)
      BigDecimal(
        (redemptions_by_month[month] || 0).to_s
      )
    end
  end
end