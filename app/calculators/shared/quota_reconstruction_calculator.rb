# frozen_string_literal: true

# Reconstructs the historical quota balance of a fund investment
# up to a specific reference date.
#
# Aggregates all quotas acquired through applications and subtracts
# all quotas liquidated via redemptions cotized on or before the
# target date.
#
# @author Moisés Reis

module Shared
  class QuotaReconstructionCalculator

    # =============================================================
    #                         PUBLIC METHODS
    # =============================================================

    class << self

      # Shortcut class method to instantiate and execute the calculator.
      #
      # @param fund_investment [FundInvestment] The record being evaluated.
      # @param date [Date, Time] Historical reference point.
      # @return [BigDecimal] Net quota balance at the specified date.
      def call(fund_investment:, date:)
        new(fund_investment:, date:).call
      end
    end

    # =============================================================
    #                         INITIALIZATION
    # =============================================================

    # Initialises the calculator with a fund investment and target date.
    #
    # @param fund_investment [FundInvestment] The record being evaluated.
    # @param date [Date, Time] Historical reference point.
    def initialize(fund_investment:, date:)
      @fund_investment = fund_investment
      @date            = date
    end

    # =============================================================
    #                         PUBLIC METHODS
    # =============================================================

    # Executes the balance reconstruction.
    #
    # @return [BigDecimal] Net balance (applications - redemptions).
    def call
      applications_total - redemptions_total
    end

    private

    # =============================================================
    #                          ATTRIBUTES
    # =============================================================

    attr_reader :fund_investment, :date

    # =============================================================
    #                          QUOTA TOTALS
    # =============================================================

    # Aggregates all quotas allocated from applications up to the target date.
    #
    # @return [BigDecimal]
    def applications_total
      BigDecimal(
        fund_investment
          .applications
          .where("cotization_date <= ?", date)
          .sum(:number_of_quotas)
          .to_s
      )
    end

    # Aggregates all quotas removed via redemptions up to the target date.
    #
    # @return [BigDecimal]
    def redemptions_total
      BigDecimal(
        fund_investment
          .redemptions
          .where("cotization_date <= ?", date)
          .sum(:redeemed_quotas)
          .to_s
      )
    end
  end
end