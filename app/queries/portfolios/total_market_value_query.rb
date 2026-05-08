module Portfolios
  class TotalMarketValueQuery
    def self.call(portfolio, date)
      portfolio.fund_investments
               .includes(:investment_fund, :applications, :redemptions)
               .sum { |fi| fi.current_market_value_on(date) }
    end
  end
end