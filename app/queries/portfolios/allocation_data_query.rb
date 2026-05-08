# Handles aggregation of allocation percentages per investment fund within a portfolio.
#
# This query object extracts fund-level allocation data and normalizes missing
# percentage values to zero.
#
# @author Moisés Reis
class Portfolios::AllocationDataQuery

  # =============================================================
  #                      1. PUBLIC METHODS
  # =============================================================

  # =============================================================
  #                          1a. CALL
  # =============================================================

  # Builds an array of fund names and their allocation percentages for a portfolio.
  #
  # @param portfolio [Portfolio] The portfolio containing fund investments.
  #
  # @return [Array<Array(String, Numeric)>] List of [fund_name, percentage] pairs.
  def self.call(portfolio)
    portfolio.fund_investments
             .includes(:investment_fund)
             .map { |fi| [fi.investment_fund.fund_name, fi.percentage_allocation || 0] }
  end
end