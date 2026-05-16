# frozen_string_literal: true

# Job responsible for triggering a performance recalculation for a specific
# fund investment on a given reference date.
#
# This job orchestrates the calculation of a historical performance snapshot
# by delegating the logic to the Performance::SnapshotCalculator service.
# It includes structured logging for enhanced observability and handles
# record cleanup via automatic discarding on missing IDs.
#
# @author Moisés Reis

class RecalculatePerformanceJob < ApplicationJob
  include StructuredLogging

  queue_as :default

  # Gracefully handle race conditions where a record is deleted after enqueuing.
  discard_on ActiveRecord::RecordNotFound

  # ==========================================================================
  # EXECUTION
  # ==========================================================================

  # @param fund_investment_id [Integer] The ID of the FundInvestment record.
  # @param reference_date [Date, String] The specific date to recalculate.
  # @return [void]
  # @raise [StandardError] Bubbles up errors to Sidekiq/SolidQueue for retry logic.
  def perform(fund_investment_id:, reference_date:)
    reference_date = reference_date.to_date

    log_info("Starting recalculation", {
      fund_investment_id: fund_investment_id,
      reference_date: reference_date
    })

    fund_investment = FundInvestment
                        .includes(:investment_fund, :portfolio, :applications, :redemptions)
                        .find(fund_investment_id)

    # Delegate core logic to the specialized Service Object
    Performance::SnapshotCalculator.call(fund_investment, reference_date)

    log_info("Recalculation completed", {
      fund_investment_id: fund_investment_id,
      reference_date: reference_date
    })
  rescue StandardError => e
    log_error("Recalculation failed", {
      error: e.message,
      error_class: e.class.name,
      fund_investment_id: fund_investment_id,
      reference_date: reference_date
    })
    raise # Re-raise to ensure the job system handles the failure/retry
  end
end
