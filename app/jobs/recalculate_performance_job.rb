# app/jobs/recalculate_performance_job.rb
class RecalculatePerformanceJob < ApplicationJob
  queue_as :default

  def perform(fund_investment_id:, reference_date:)
    fi = FundInvestment
           .includes(:investment_fund, :portfolio, :applications, :redemptions)
           .find(fund_investment_id)

    job = PerformanceCalculationJob.new
    job.send(:calculate_snapshot!, fi, reference_date.to_date)
  end
end
