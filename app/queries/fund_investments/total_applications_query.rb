# frozen_string_literal: true

# Calculates the total amount applied to a fund investment.
#
# This query aggregates the gross financial value of all
# application transactions associated with a fund investment.
#
# @author Moisés Reis
class FundInvestments::TotalApplicationsQuery

  # =============================================================
  #                        PUBLIC METHODS
  # =============================================================

  # Calculates the total amount applied to a fund investment.
  #
  # @param fund_investment [FundInvestment] The investment being evaluated.
  #
  # @return [BigDecimal] The total applied amount.
  def self.call(fund_investment)
    BigDecimal(
      fund_investment
        .applications
        .sum(:financial_value)
        .to_s
    )
  end
end
