# frozen_string_literal: true

# Calculates the total redeemed amount for a fund investment.
#
# This query aggregates the total liquid value of all redemption
# transactions associated with a fund investment.
#
# @author Moisés Reis
class FundInvestments::TotalRedemptionsQuery

  # =============================================================
  #                        PUBLIC METHODS
  # =============================================================

  # Calculates the total redeemed amount of a fund investment.
  #
  # @param fund_investment [FundInvestment] The investment being evaluated.
  #
  # @return [BigDecimal] The total redeemed amount.
  def self.call(fund_investment)
    BigDecimal(
      fund_investment
        .redemptions
        .sum(:redeemed_liquid_value)
        .to_s
    )
  end
end
