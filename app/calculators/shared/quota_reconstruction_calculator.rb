# frozen_string_literal: true

# Service responsible for reconstructing the historical quota balance of a 
# fund investment up to a specific reference date.
#
# This calculator aggregates all quotas acquired through applications and 
# subtracts all quotas liquidated via redemptions cotized on or before the target date.
#
# @author Moisés Reis

module Shared
  class QuotaReconstructionCalculator

    class << self
      # Shortcut class method to instantiate and execute the calculator.
      #
      # @param fund_investment [FundInvestment] The record whose balance is being calculated.
      # @param date [Date, Time] The historical reference point for the reconstruction.
      # @return [BigDecimal] The net quota balance at the specified date.
      def call(fund_investment:, date:)
        new(fund_investment:, date:).call
      end
    end

    # ==========================================================================
    # INITIALIZATION
    # ==========================================================================

    # @param fund_investment [FundInvestment] The record whose balance is being calculated.
    # @param date [Date, Time] The historical reference point for the reconstruction.
    def initialize(fund_investment:, date:)
      @fund_investment = fund_investment
      @date            = date
    end

    # ==========================================================================
    # EXECUTION
    # ==========================================================================

    # Executes the balance reconstruction.
    # @return [BigDecimal] Net balance ($applications - redemptions$).
    def call
      applications_total - redemptions_total
    end

    private

    attr_reader :fund_investment, :date

    # Aggregates all quotas allocated from applications up to the target date.
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