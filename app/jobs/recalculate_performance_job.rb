# frozen_string_literal: true

# Job responsible for triggering a performance recalculation for a specific
# fund investment on a given reference date.
#
# This job orchestrates the lifecycle of a monthly financial calculation by fetching
# the core asset and delegating the persistence steps to the specialized 
# Jobs::PerformanceSnapshotCreator service layer.
#
# @author Moisés Reis

class RecalculatePerformanceJob < ApplicationJob
  include StructuredLogging

  queue_as :default

  # Handle situations where the target database record is removed right before processing.
  discard_on ActiveRecord::RecordNotFound

  # ==========================================================================
  # EXECUTION
  # ==========================================================================

  # Executes the background task orchestrating data dependencies.
  #
  # @param fund_investment_id [Integer] The unique identifier for the targeted FundInvestment.
  # @param reference_date [Date, String] The specific calculation timeline pointer.
  # @return [void]
  # @raise [StandardError] Cascades exceptions to trigger background infrastructure handling/retries.
  def perform(fund_investment_id:, reference_date:)
    reference_date = reference_date.to_date

    log_info("Starting recalculation", {
      fund_investment_id: fund_investment_id,
      reference_date: reference_date
    })

    fund_investment = FundInvestment
                        .includes(:investment_fund, :portfolio, :applications, :redemptions)
                        .find(fund_investment_id)

    # Delegates to the execution layer responsible for interpreting calculations and state saving
    Jobs::PerformanceSnapshotCreator.call(fund_investment, reference_date)

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

    raise
  end
end