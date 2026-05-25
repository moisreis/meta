# frozen_string_literal: true

# Calculates the return percentage for a fund investment.
#
# This query computes the percentage return relative to the total
# invested capital based on the unrealized gain or loss.
#
# @author Moisés Reis
class FundInvestments::ReturnPercentageQuery

  # =============================================================
  #                        PUBLIC METHODS
  # =============================================================

  # Calculates the return percentage of a fund investment.
  #
  # Delegates unrealized gain/loss calculation to
  # {FundInvestments::UnrealizedGainLossQuery}.
  #
  # @param fund_investment [FundInvestment] The investment being evaluated.
  # @param date [Date] The reference date used for valuation.
  #
  # @return [BigDecimal] The return percentage.
  def self.call(fund_investment, date = Date.current)
    total_invested_value = fund_investment.total_invested_value

    return BigDecimal("0") if total_invested_value.zero?

    unrealized_gain_loss = FundInvestments::UnrealizedGainLossQuery.call(
        fund_investment,
        date
      )

    (unrealized_gain_loss / total_invested_value) * 100
  end
end
