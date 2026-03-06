class PortfolioAllocationCalculator
  def self.recalculate!(portfolio)
    investments = portfolio.fund_investments.includes(:applications, :redemptions)

    total = investments.sum do |fi|
      fi.applications.sum(:financial_value).to_f -
        fi.redemptions.sum(:redeemed_liquid_value).to_f
    end

    return if total <= 0

    investments.each do |fi|
      invested = fi.applications.sum(:financial_value).to_f -
                 fi.redemptions.sum(:redeemed_liquid_value).to_f

      fi.update_columns(
        total_invested_value: [invested, 0].max,
        percentage_allocation: (invested / total * 100).round(4)
      )
    end
  end
end