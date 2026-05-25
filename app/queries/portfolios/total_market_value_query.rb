# frozen_string_literal: true

# Calculates the total market value of all fund investments in a portfolio
# at a given date.
#
# @author Moisés Reis

module Portfolios
  class TotalMarketValueQuery
    
    # @param portfolio [Portfolio]
    # @param date [Date]
    # @return [BigDecimal]
    def self.call(portfolio, date)
      portfolio.fund_investments
               .includes(:investment_fund, :applications, :redemptions)
               .sum { |fi| fi.current_market_value_on(date) }
    end
  end
end
