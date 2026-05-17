# frozen_string_literal: true

# System-wide orchestration job responsible for executing scheduled monthly
# performance calculations across all fund investments.
#
# This batch job iterates through all available fund investments to generate
# historical performance snapshots while isolating individual processing
# failures to prevent a single invalid record from interrupting the global
# execution flow.
#
# Once all investment positions are processed, the job triggers downstream
# checking account consolidation routines to finalize financial aggregates.
#
# @author Moisés Reis

class PerformanceCalculationJob < ApplicationJob
  queue_as :default

  # =============================================================
  # PUBLIC METHODS
  # =============================================================

  # Executes the historical monthly performance calculation workflow.
  #
  # The calculation reference month is derived from the month immediately
  # preceding the provided target date.
  #
  # @param target_date [Date] The orchestration anchor date used to derive
  #   the calculation reference month.
  #
  # @return [void]
  #
  def perform(target_date: Date.yesterday)
    Rails.logger.info(
      "[PerformanceCalculationJob] Starting for #{target_date}"
    )

    reference_date = target_date.prev_month

    FundInvestment
      .includes(:investment_fund, :portfolio, :applications, :redemptions)
      .find_each do |fund_investment|

      begin
        Jobs::PerformanceSnapshotCreator.call(
          fund_investment,
          reference_date
        )
      rescue StandardError => e
        Rails.logger.error(
          "[PerformanceCalculationJob] " \
            "Skipping FundInvestment##{fund_investment.id} " \
            "(#{fund_investment.investment_fund&.cnpj}): " \
            "#{e.class} — #{e.message}"
        )
      end

    end

    Jobs::CheckingAccountConsolidationService.call(reference_date)

    Rails.logger.info(
      "[PerformanceCalculationJob] Finished successfully"
    )
  end

end