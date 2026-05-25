# frozen_string_literal: true

# Provides logic for reconstructing historical quota positions
# of a fund investment at a given point in time.
#
# This module aggregates application and redemption movements
# up to a specific date to compute the net quota balance.
#
# @author Moisés Reis

module Portfolios
  module QuotaReconstruction

    # ===========================================================
    #                   PUBLIC INTERFACE
    # ===========================================================

    # Reconstructs the quota balance of a fund investment at a
    # specific date based on historical applications and redemptions.
    #
    # @param fund_investment [FundInvestment]
    #   The investment whose quota history is being reconstructed.
    #
    # @param date [Date, Time]
    #   Cutoff date used to filter financial movements.
    #
    # @return [BigDecimal]
    #   Net quota balance at the specified date.
    #
    def reconstruct_quotas_at(fund_investment, date)
      apps = fund_investment.applications
                            .where("cotization_date <= ?", date)
                            .sum(:number_of_quotas)

      reds = fund_investment.redemptions
                            .where("cotization_date <= ?", date)
                            .sum(:redeemed_quotas)

      BigDecimal(apps.to_s) - BigDecimal(reds.to_s)
    end
  end
end