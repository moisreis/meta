# frozen_string_literal: true

# Calculates the unrealized gain or loss for a fund investment.
#
# This query determines the difference between the current market
# value and the total invested amount for a given reference date.
#
# The result represents the potential profit or loss of the
# position if liquidated at the current quota valuation.
#
# @author Moisés Reis
class FundInvestments::UnrealizedGainLossQuery

  # =============================================================
  #                        PUBLIC METHODS
  # =============================================================

  # Calculates the unrealized gain or loss of a fund investment.
  #
  # Delegates market value calculation to
  # {FundInvestments::CurrentMarketValueQuery}.
  #
  # @param fund_investment [FundInvestment] The investment being evaluated.
  # @param date [Date] The reference date used for valuation.
  #
  # @return [BigDecimal] The unrealized gain or loss amount.
  def self.call(fund_investment, date = Date.current)
    current_market_value = FundInvestments::CurrentMarketValueQuery.call(
        fund_investment,
        date
      )

    current_market_value - fund_investment.total_invested_value
  end
end
