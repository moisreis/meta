module Portfolios
  class FundQuotaValueQuery
    def self.call(portfolio, date)
      subquery = FundValuation
        .select("DISTINCT ON (fund_cnpj) fund_cnpj, quota_value")
        .where("date <= ?", date)
        .where("EXTRACT(DOW FROM date) NOT IN (0, 6)")
        .order("fund_cnpj, date DESC")

      FundInvestment
        .joins(:investment_fund)
        .joins("INNER JOIN (#{subquery.to_sql}) fv ON fv.fund_cnpj = investment_funds.cnpj")
        .where(portfolio_id: portfolio.id)
        .pluck("fund_investments.id", "fv.quota_value")
        .to_h
    end
  end
end