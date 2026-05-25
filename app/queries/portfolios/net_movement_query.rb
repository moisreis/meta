# frozen_string_literal: true

# Calculates the net movement (applications minus redemptions) per fund
# investment for a given month.
#
# @author Moisés Reis

module Portfolios
  class NetMovementQuery
    # @param portfolio [Portfolio]
    # @param date [Date]
    # @return [Hash{Integer => BigDecimal}]
    def self.call(portfolio, date)
      start_date = date.to_date.beginning_of_month
      end_date   = date.to_date.end_of_month

      applications = Application
        .joins(:fund_investment)
        .where(fund_investments: { portfolio_id: portfolio.id })
        .where(request_date: start_date..end_date)
        .group(:fund_investment_id)
        .sum(:financial_value)

      redemptions = Redemption
        .joins(:fund_investment)
        .where(fund_investments: { portfolio_id: portfolio.id })
        .where(request_date: start_date..end_date)
        .group(:fund_investment_id)
        .sum(:redeemed_liquid_value)

      all_fi_ids = (applications.keys + redemptions.keys).uniq

      all_fi_ids.index_with do |fi_id|
        BigDecimal(applications.fetch(fi_id, 0).to_s) -
          BigDecimal(redemptions.fetch(fi_id, 0).to_s)
      end
    end
  end
end
