# frozen_string_literal: true

module FundInvestments

  # Reconstructs the historical market value for a fund investment
  # on a specific reference date.
  #
  # This query calculates the current financial position of an
  # investment by multiplying net held quotas by the fund quota
  # value at the given date. It accounts for both applications
  # and redemptions to determine net quota holdings.
  #
  # @author Moisés Reis  
  class MarketValueOnQuery

    # =============================================================
    #                      RESULT STRUCTURE
    # =============================================================

    Result = Struct.new(
      :value,
      :quota,
      :date,
      keyword_init: true
    )

    # =============================================================
    #                         ENTRYPOINT
    # =============================================================

    # Dispatches the market value reconstruction.
    #
    # @param fund_investment [FundInvestment] The investment being evaluated.
    # @param date [Date] The reference date for quota pricing.
    #
    # @return [Result]
    def self.call(fund_investment:, date:)
      new(fund_investment: fund_investment, date: date).call
    end

    # =============================================================
    #                       INITIALIZATION
    # =============================================================

    # @param fund_investment [FundInvestment]
    # @param date [Date]
    #
    # @return [void]
    def initialize(fund_investment:, date:)
      @fund_investment = fund_investment
      @date = date
    end

    # =============================================================
    #                       QUERY WORKFLOW
    # =============================================================

    # Reconstructs the market value for the given date.
    #
    # @return [Result]
    def call
      quota = investment_fund.quota_value_on(@date)

      Result.new(
        value: calculate_value(quota),
        quota: quota,
        date: @date
      )
    end

    private

    # =============================================================
    #                      PRIVATE HELPERS
    # =============================================================

    attr_reader :fund_investment

    # Returns the associated investment fund.
    #
    # @return [InvestmentFund]
    def investment_fund
      @fund_investment.investment_fund
    end

    # Calculates the financial value from quota price.
    #
    # Returns nil when no quota value is available for the date.
    #
    # @param quota [BigDecimal, nil]
    #
    # @return [BigDecimal, nil]
    def calculate_value(quota)
      return nil unless quota

      (net_quotas * quota).round(2)
    end

    # Computes net held quotas (applications minus redemptions).
    #
    # @return [BigDecimal]
    def net_quotas
      applied_quotas - redeemed_quotas
    end

    # Sums all application quotas for the investment.
    #
    # @return [BigDecimal]
    def applied_quotas
      @fund_investment.applications.sum(:number_of_quotas)
    end

    # Sums all redeemed quotas for the investment.
    #
    # @return [BigDecimal]
    def redeemed_quotas
      @fund_investment.redemptions.sum(:redeemed_quotas)
    end
  end
end
