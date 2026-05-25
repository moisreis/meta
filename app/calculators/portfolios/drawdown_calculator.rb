# frozen_string_literal: true

# Calculates the drawdown series from a portfolio yield timeline.
#
# Computes the peak-to-trough decline at each point in the series,
# returning [date, drawdown_percentage] pairs suitable for charting.
#
# @author Moisés Reis

module Portfolios
  class DrawdownCalculator

    # =============================================================
    #                         PUBLIC METHODS
    # =============================================================

    # Computes the drawdown series from a yield timeline.
    #
    # @param portfolio_yield_series [Array<Array(Date, Numeric)>]
    #   Ordered pairs of [date, return_percentage].
    # @return [Array<Array(Date, Numeric)>]
    #   Drawdown series with values rounded to 2 decimal places.
    def self.call(portfolio_yield_series)
      peak = 0
      portfolio_yield_series.map do |date, return_pct|
        peak = [peak, return_pct].max
        drawdown = peak == 0 ? 0 : (return_pct - peak)
        [date, drawdown.round(2)]
      end
    end
  end
end