# app/calculators/portfolios/drawdown_calculator.rb
module Portfolios
  class DrawdownCalculator
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