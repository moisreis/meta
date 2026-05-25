# frozen_string_literal: true

module FundInvestments

  # Queries transaction distribution metrics for chart rendering.
  #
  # This query aggregates total application and redemption amounts
  # for a fund investment into a pie chart compatible dataset.
  #
  # @author Moisés Reis  
  class TransactionDistributionChartQuery

    # =============================================================
    #                        PUBLIC METHODS
    # =============================================================

    # Builds transaction distribution dataset.
    #
    # @param fund_investment [FundInvestment] Target investment entity.
    #
    # @return [Hash<String, Numeric>] Aggregated chart dataset.
    def self.call(fund_investment)
      {
        "Aplicações" => total_applications(fund_investment),
        "Resgates"   => total_redemptions(fund_investment)
      }
    end

    # =============================================================
    #                       PRIVATE METHODS
    # =============================================================

    private_class_method

    # Calculates total application value.
    #
    # @param fund_investment [FundInvestment]
    #
    # @return [BigDecimal]
    def self.total_applications(fund_investment)
      fund_investment
        .applications
        .sum(:financial_value)
    end

    # Calculates total redemption value.
    #
    # @param fund_investment [FundInvestment]
    #
    # @return [BigDecimal]
    def self.total_redemptions(fund_investment)
      fund_investment
        .redemptions
        .sum(:redeemed_liquid_value)
    end
  end
end
