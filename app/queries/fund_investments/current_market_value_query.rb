# frozen_string_literal: true

# Calculates the current market value for a fund investment on a
# given date.
#
# This query encapsulates the valuation logic used to determine
# the current financial value of held quotas based on the
# investment fund quota price available for the provided
# reference date.
#
# Missing quota values or held quotas are normalized to zero in
# order to provide a safe and predictable monetary result.
#
# @author Moisés Reis
class FundInvestments::CurrentMarketValueQuery

  # =============================================================
  #                        PUBLIC METHODS
  # =============================================================

  # Calculates the current market value of a fund investment.
  #
  # @param fund_investment [FundInvestment] The investment being evaluated.
  # @param date [Date] The reference date used to retrieve quota pricing.
  #
  # @return [BigDecimal] The calculated market value or zero when
  #   unavailable.
  def self.call(fund_investment, date = Date.current)
    quota = fund_investment.investment_fund.quota_value_on(date)
    total_quotas = fund_investment.total_quotas_held

    return BigDecimal("0") unless quota && total_quotas

    value = total_quotas * quota

    value < BigDecimal("1") ? BigDecimal("0") : value
  end
end
