# frozen_string_literal: true

# Service responsible for consolidating checking account balances by
# portfolio for a given reference month.
#
# This service aggregates all checking account balances grouped by portfolio
# and logs the resulting totals for auditing and operational visibility.
#
# @author Moisés Reis

module Jobs  
  class CheckingAccountConsolidationService

    # =============================================================
    # CLASS METHODS
    # =============================================================

    class << self

      # Executes the checking account consolidation process.
      #
      # @param reference_date [Date, Time, DateTime] The reference month used
      #   for balance consolidation.
      #
      # @return [Hash<Integer, BigDecimal>] A hash mapping portfolio IDs to
      #   consolidated checking account balances.
      #
      def call(reference_date)
        new(reference_date).call
      end

    end

    # =============================================================
    # INITIALIZATION
    # =============================================================

    # Initializes the checking account consolidation service.
    #
    # @param reference_date [Date, Time, DateTime] The reference month used
    #   for balance consolidation.
    #
    def initialize(reference_date)
      @reference_date = reference_date.to_date
    end

    # =============================================================
    # PUBLIC METHODS
    # =============================================================

    # Consolidates checking account balances grouped by portfolio.
    #
    # Logs each consolidated total individually for traceability purposes.
    #
    # @return [Hash<Integer, BigDecimal>] A hash mapping portfolio IDs to
    #   consolidated checking account balances.
    #
    # @raise [StandardError] Logged internally when the consolidation process
    #   fails unexpectedly.
    #
    def call
      totals = CheckingAccount
                 .where(reference_date: period_end)
                 .group(:portfolio_id)
                 .sum(:balance)

      if totals.empty?
        Rails.logger.info(
          "[Jobs::CheckingAccountConsolidationService] " \
            "No checking accounts found for #{period_end}"
        )

        return {}
      end

      totals.each do |portfolio_id, total_balance|
        Rails.logger.info(
          "[Jobs::CheckingAccountConsolidationService] " \
            "Portfolio ##{portfolio_id} — checking accounts total " \
            "for #{period_end}: R$ #{total_balance}"
        )
      end

      totals
    rescue StandardError => e
      Rails.logger.warn(
        "[Jobs::CheckingAccountConsolidationService] " \
          "Could not consolidate checking accounts: #{e.message}"
      )

      {}
    end

    private

    # =============================================================
    # ATTRIBUTES
    # =============================================================

    # @!attribute [r] reference_date
    #   @return [Date] The normalized reference month used for consolidation.
    #
    attr_reader :reference_date

    # =============================================================
    # PERIOD HELPERS
    # =============================================================

    # Returns the final day of the reference month.
    #
    # @return [Date] The last day of the reference month.
    #
    def period_end
      @period_end ||= reference_date.end_of_month
    end

  end
end