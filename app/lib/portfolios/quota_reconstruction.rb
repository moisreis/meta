# frozen_string_literal: true

# app/lib/portfolios/quota_reconstruction.rb
#
# Provides logic for reconstructing historical quota positions of a fund
# investment at a given point in time.
#
# Aggregates application and redemption movements up to a specific date
# to compute the net quota balance.
#
# @author  Moisés Reis

module Portfolios
  module QuotaReconstruction

    # == Public Interface =====================================================

    # Reconstructs the quota balance of a fund investment at a specific date
    # based on historical applications and redemptions.
    #
    # @param fund_investment [FundInvestment] the investment whose quota history is being reconstructed.
    # @param date            [Date, Time]     cutoff date used to filter financial movements.
    # @return [BigDecimal] net quota balance at the specified date.
    def reconstruct_quotas_at(fund_investment, date)
      apps = applications_up_to(fund_investment, date)
      reds = redemptions_up_to(fund_investment, date)

      BigDecimal(apps.to_s) - BigDecimal(reds.to_s)
    end


    private


    # == Private Methods ======================================================

    # Sums all application quotas for a fund investment up to a given date.
    #
    # @param fund_investment [FundInvestment] the target investment.
    # @param date            [Date, Time]     cutoff date for filtering.
    # @return [Numeric] total number of applied quotas.
    def applications_up_to(fund_investment, date)
      fund_investment.applications
                     .where("cotization_date <= ?", date)
                     .sum(:number_of_quotas)
    end

    # Sums all redeemed quotas for a fund investment up to a given date.
    #
    # @param fund_investment [FundInvestment] the target investment.
    # @param date            [Date, Time]     cutoff date for filtering.
    # @return [Numeric] total number of redeemed quotas.
    def redemptions_up_to(fund_investment, date)
      fund_investment.redemptions
                     .where("cotization_date <= ?", date)
                     .sum(:redeemed_quotas)
    end

  end
end