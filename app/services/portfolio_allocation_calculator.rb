# === portfolio_allocation_calculator.rb
#
# Description:: Computes the financial distribution of assets within a portfolio.
#               Updates the total invested values and the weight of each fund
#               relative to the entire portfolio balance.
#
# FIX: All arithmetic has been migrated from Float to BigDecimal to prevent
# floating-point rounding errors in financial calculations. Float accumulates
# rounding error across multiplications and divisions; BigDecimal is exact up
# to the specified precision, which is critical for percentage_allocation sums
# that must not drift above or below 100% due to representation error.
#
class PortfolioAllocationCalculator

  # =============================================================
  #                        Public Methods
  # =============================================================

  # == recalculate!
  #
  # @author Moisés Reis
  #
  # Updates every investment in a portfolio with its current market value share.
  # Uses BigDecimal throughout to avoid floating-point drift.
  #
  # Parameters:: - *portfolio* - The portfolio record containing the investments.
  def self.recalculate!(portfolio)
    investments = portfolio.fund_investments.includes(:applications, :redemptions, :investment_fund)

    market_values = investments.index_with do |fi|
      mv = fi.current_market_value
      mv.positive? ? mv : net_invested(fi)
    end

    total = market_values.values.sum
    return if total <= 0

    investments.each do |fi|
      gross_invested = BigDecimal(fi.applications.sum(:financial_value).to_s)
      net            = (gross_invested - BigDecimal(fi.redemptions.sum(:redeemed_liquid_value).to_s))
                         .clamp(BigDecimal("0"), BigDecimal("Infinity"))

      allocation = ((market_values[fi] / total) * BigDecimal("100")).round(4)

      fi.update_columns(
        total_invested_value: net,
        percentage_allocation: allocation
      )
    end
  end

  # =============================================================
  #                        Private Methods
  # =============================================================

  # == net_invested
  #
  # @author Moisés Reis
  #
  # Calculates the remaining capital in an investment using BigDecimal arithmetic.
  #
  # Parameters:: - *fi* - The fund investment object being analysed.
  #
  # Returns:: - A BigDecimal representing the current net capital.
  def self.net_invested(fi)
    gross = BigDecimal(fi.applications.sum(:financial_value).to_s)
    (gross - BigDecimal(fi.redemptions.sum(:redeemed_liquid_value).to_s))
      .clamp(BigDecimal("0"), BigDecimal("Infinity"))
  end

  private_class_method :net_invested
end
