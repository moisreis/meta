module Portfolios
  class NetMovementQuery
    def self.call(portfolio, date)
      start_date = date.to_date.beginning_of_month
      end_date   = date.to_date.end_of_month

      Application
        .joins(:fund_investment)
        .where(fund_investments: { portfolio_id: portfolio.id })
        .where(request_date: start_date..end_date)
        .group(:fund_investment_id)
        .sum(:financial_value)
        .merge(
          Redemption
            .joins(:fund_investment)
            .where(fund_investments: { portfolio_id: portfolio.id })
            .where(request_date: start_date..end_date)
            .group(:fund_investment_id)
            .sum(:redeemed_liquid_value)
        )
        .transform_values { |apps_minus_reds| apps_minus_reds }
    end
  end
end