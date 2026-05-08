module Portfolios
  class MarketValueByFundQuery
    def self.call(portfolio, date)
      quotas_by_fund = Application
        .joins(:fund_investment)
        .where(fund_investments: { portfolio_id: portfolio.id })
        .where("cotization_date <= ?", date)
        .group(:fund_investment_id)
        .sum(:number_of_quotas)

      redemptions_by_fund = Redemption
        .joins(:fund_investment)
        .where(fund_investments: { portfolio_id: portfolio.id })
        .where("cotization_date <= ?", date)
        .group(:fund_investment_id)
        .sum(:redeemed_quotas)

      funds = FundInvestment
        .joins(:investment_fund)
        .where(portfolio_id: portfolio.id)
        .includes(:investment_fund)

      funds.each_with_object({}) do |fi, hash|
        quota_price = fi.investment_fund.quota_value_on(date)
        next unless quota_price

        net_quotas = quotas_by_fund[fi.id].to_f - redemptions_by_fund[fi.id].to_f
        hash[fi.id] = net_quotas * quota_price
      end
    end
  end
end