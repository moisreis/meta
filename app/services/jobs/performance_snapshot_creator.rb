# frozen_string_literal: true

# Command responsible for persisting a monthly performance snapshot for a
# FundInvestment using calculated performance metrics.
#
# This command coordinates snapshot calculation, stale history cleanup,
# and persistence of consolidated monthly performance metrics.
#
# @author Moisés Reis

module Jobs
  class PerformanceSnapshotCreator

    # =============================================================
    # CLASS METHODS
    # =============================================================

    class << self

      # Executes the performance snapshot persistence workflow.
      #
      # @param fund_investment [FundInvestment] The investment whose
      #   performance snapshot will be persisted.
      # @param reference_date [Date, Time, DateTime] The month reference date.
      #
      # @return [PerformanceHistory, nil] The persisted performance history
      #   record or nil when snapshot metrics cannot be calculated.
      #
      def call(fund_investment, reference_date)
        new(fund_investment, reference_date: reference_date).call
      end

    end

    # =============================================================
    # INITIALIZATION
    # =============================================================

    # Initializes the performance snapshot creator.
    #
    # @param fund_investment [FundInvestment] The investment whose
    #   performance snapshot will be persisted.
    # @param reference_date [Date, Time, DateTime] The month reference date.
    #
    def initialize(fund_investment, reference_date:)
      @fund_investment = fund_investment
      @reference_date = reference_date.to_date
    end

    # =============================================================
    # PUBLIC METHODS
    # =============================================================

    # Persists the calculated performance snapshot for the configured period.
    #
    # Removes stale historical records when both starting and ending quota
    # balances are zero or negative.
    #
    # @return [PerformanceHistory, nil] The persisted performance history
    #   record or nil when snapshot metrics cannot be calculated or when
    #   stale history cleanup occurs.
    #
    # @raise [ActiveRecord::RecordInvalid] When the performance history
    #   record cannot be persisted.
    #
    def call
      metrics = Shared::PerformanceSnapshotCalculator.call(
        fund_investment,
        reference_date
      )

      return unless metrics

      if metrics.quotas_at_start <= 0 && metrics.quotas_at_end <= 0
        stale_history_for(period_end).destroy_all
        return
      end

      performance.update!(performance_attributes(metrics))

      performance
    end

    private

    # =============================================================
    # ATTRIBUTES
    # =============================================================

    # @!attribute [r] fund_investment
    #   @return [FundInvestment] The investment being processed.
    #
    # @!attribute [r] reference_date
    #   @return [Date] The normalized month reference date.
    #
    attr_reader :fund_investment, :reference_date

    # =============================================================
    # PERFORMANCE RECORD HELPERS
    # =============================================================

    # Returns the performance history record for the configured period.
    #
    # Initializes a new record when no persisted snapshot exists.
    #
    # @return [PerformanceHistory] The performance history record for
    #   the configured investment and period.
    #
    def performance
      @performance ||= PerformanceHistory.find_or_initialize_by(
        portfolio_id: fund_investment.portfolio_id,
        fund_investment_id: fund_investment.id,
        period: period_end
      )
    end

    # Builds the persistence payload from calculated performance metrics.
    #
    # @param metrics [Shared::PerformanceSnapshotCalculator::Result]
    #   The calculated performance metrics.
    #
    # @return [Hash] The normalized persistence attributes payload.
    #
    def performance_attributes(metrics)
      {
        initial_balance: metrics.initial_balance,
        earnings: metrics.earnings,
        monthly_return: metrics.monthly_return,
        yearly_return: metrics.yearly_return,
        last_12_months_return: metrics.last_12_months_return
      }
    end

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

    # =============================================================
    # STALE HISTORY CLEANUP
    # =============================================================

    # Returns historical performance records eligible for cleanup.
    #
    # @param period [Date] The target historical period.
    #
    # @return [ActiveRecord::Relation<PerformanceHistory>] The stale
    #   performance history records matching the configured investment
    #   and period.
    #
    def stale_history_for(period)
      PerformanceHistory.where(
        portfolio_id: fund_investment.portfolio_id,
        fund_investment_id: fund_investment.id,
        period: period
      )
    end

  end
end