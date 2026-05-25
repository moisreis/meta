# frozen_string_literal: true

# Calculates the total realized and unrealized gain for a fund
# investment.
#
# This query determines the overall financial result of an
# investment position by combining:
# - Total redeemed value
# - Current market value
# - Total applied capital
#
# @author Moisés Reis
class FundInvestments::TotalGainQuery

  # =============================================================
  #                        PUBLIC METHODS
  # =============================================================

  # Calculates the total gain or loss of a fund investment.
  #
  # Delegates sub-calculations to {TotalRedemptionsQuery},
  # {CurrentMarketValueQuery}, and {TotalApplicationsQuery}.
  #
  # @param fund_investment [FundInvestment] The investment being evaluated.
  # @param date [Date] The reference date used for valuation.
  #
  # @return [BigDecimal] The total gain or loss amount.
  def self.call(fund_investment, date = Date.current)
    total_redemptions = FundInvestments::TotalRedemptionsQuery.call(
        fund_investment
      )

    current_market_value = FundInvestments::CurrentMarketValueQuery.call(
        fund_investment,
        date
      )

    total_applications = FundInvestments::TotalApplicationsQuery.call(
        fund_investment
      )

    total_redemptions + current_market_value - total_applications
  end
end
