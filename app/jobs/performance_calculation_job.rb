# === performance_calculation_job.rb
#
# Description:: Calculates and persists monthly financial performance snapshots.
#
# Formula — monthly_return::
#   (quota_end - quota_start) / quota_start
#   Tracks the fund's own unit price variation, independent of the investor's
#   cash-flow timing. Matches the "Rentabilidade do Fundo" figure reported by
#   fund managers and used in official statements.
#
# Formula — yearly_return / last_12_months_return::
#   Geometric compounding of monthly_return values already stored in
#   performance_histories. This avoids distortion caused by large mid-period
#   cash flows that would skew a simple balance-over-balance ratio.
#
# FIX (resilience): Each calculate_snapshot! call is now wrapped in its own
# begin/rescue block. A missing quota valuation or any unexpected error for
# one fund will be logged and skipped rather than aborting the entire job,
# leaving the other funds' snapshots unprocessed.
#
# FIX (monthly_return): Replaced Modified Dietz with direct quota variation.
# Modified Dietz measured investor-level return (affected by application timing);
# quota variation measures the fund's intrinsic performance, aligning with
# the figures published by the fund manager.
#
# FIX (yearly_return / last_12_months_return): Replaced balance-over-balance
# ratio with geometric compounding of stored monthly_return values. The old
# approach produced extreme distortions (e.g. 2969%) when a fund received a
# large application relative to its opening balance.
#
class PerformanceCalculationJob < ApplicationJob
  queue_as :default

  # == perform
  #
  # @author Moisés Reis
  #
  # Parameters:: - *target_date* - Reference date; the previous calendar month is processed.
  def perform(target_date: Date.yesterday)
    Rails.logger.info("[PerformanceCalculationJob] Starting for #{target_date}")

    reference_date = target_date.prev_month

    FundInvestment
      .includes(:investment_fund, :portfolio, :applications, :redemptions)
      .find_each do |fund_investment|
      begin
        calculate_snapshot!(fund_investment, reference_date)
      rescue StandardError => e
        Rails.logger.error(
          "[PerformanceCalculationJob] Skipping FundInvestment##{fund_investment.id} " \
            "(#{fund_investment.investment_fund&.cnpj}): #{e.class} — #{e.message}"
        )
      end
    end

    consolidate_checking_accounts!(reference_date)

    Rails.logger.info("[PerformanceCalculationJob] Finished successfully")
  end

  private

  # == calculate_snapshot!
  #
  # @author Moisés Reis
  #
  # Computes the performance metrics for a single investment fund during a specific month
  # and upserts the result into performance_histories.
  def calculate_snapshot!(fund_investment, reference_date)
    fund = fund_investment.investment_fund
    portfolio = fund_investment.portfolio

    period_start = reference_date.beginning_of_month
    period_end = reference_date.end_of_month

    # CRITICAL: Use (period_start - 1.day) to get the last business day of the PREVIOUS month.
    # This ensures initial_balance reflects the portfolio's opening value at month start,
    # NOT the intra-month value. Using period_start directly could pick up incorrect valuations
    # if the first day of the month is a weekend or has no valuation data.
    quota_start = find_quota_value(fund.cnpj, period_start - 1.day)
    quota_end = find_quota_value(fund.cnpj, period_end)

    return unless quota_start && quota_end

    quotas_at_start =
      Performance::QuotaReconstructionCalculator.call(
        fund_investment:,
        date: period_start - 1.day
      )

    quotas_at_end =
      Performance::QuotaReconstructionCalculator.call(
        fund_investment:,
        date: period_end
      )

    return if quotas_at_start <= 0 && quotas_at_end <= 0

    initial_balance = quotas_at_start * quota_start
    final_balance = quotas_at_end * quota_end

    period_applications = fund_investment.applications
                                         .where(cotization_date: period_start..period_end)
    period_redemptions = fund_investment.redemptions
                                        .where(cotization_date: period_start..period_end)

    net_cash_flow = period_applications.sum(:financial_value) -
                    period_redemptions.sum(:redeemed_liquid_value)

    earnings = final_balance - initial_balance - net_cash_flow


    monthly_return = percentage(quota_end - quota_start, quota_start)

    if initial_balance <= 0 && final_balance <= 0
      # Fundo sem posição neste período — garante limpeza se já existia registro stale
      PerformanceHistory
        .where(portfolio_id: portfolio.id,
               fund_investment_id: fund_investment.id,
               period: period_end)
        .destroy_all
      return
    end

    performance = PerformanceHistory.find_or_initialize_by(
      portfolio_id: portfolio.id,
      fund_investment_id: fund_investment.id,
      period: period_end
    )

    performance.update!(
      initial_balance: initial_balance,
      earnings: earnings,
      monthly_return: monthly_return,
      yearly_return: calculate_yearly_return(performance, monthly_return),
      last_12_months_return: calculate_last_12_months_return(performance, monthly_return)
    )
  end

  # == consolidate_checking_accounts!
  #
  # @author Moisés Reis
  #
  # Aggregates balances for checking accounts associated with each portfolio.
  def consolidate_checking_accounts!(reference_date)
    period_end = reference_date.end_of_month

    totals = CheckingAccount
               .where(reference_date: period_end)
               .group(:portfolio_id)
               .sum(:balance)

    if totals.empty?
      Rails.logger.info("[PerformanceCalculationJob] No checking accounts found for #{period_end}")
      return
    end

    totals.each do |portfolio_id, total_balance|
      Rails.logger.info(
        "[PerformanceCalculationJob] Portfolio ##{portfolio_id} — " \
          "Checking accounts total for #{period_end}: R$ #{total_balance}"
      )
    end
  rescue StandardError => e
    Rails.logger.warn("[PerformanceCalculationJob] Could not consolidate checking accounts: #{e.message}")
  end

  # == calculate_yearly_return
  #
  # @author Moisés Reis
  #
  # Compounds all stored monthly_return values for the current calendar year,
  # including the current month being persisted.
  #
  # Using geometric compounding rather than balance-over-balance avoids extreme
  # distortions when large applications occur relative to the opening balance
  # (e.g. a fund that started the year with R$17k and received R$500k in January).
  #
  # Returns:: - The YTD percentage return as a BigDecimal, or nil if no monthly
  #             returns are available for the current year.
  def calculate_yearly_return(performance, current_monthly_return)
    return nil if current_monthly_return.nil?

    prior_returns = PerformanceHistory
                      .where(fund_investment_id: performance.fund_investment_id)
                      .where(
                        "period >= ? AND period < ?",
                        performance.period.beginning_of_year,
                        performance.period
                      )
                      .where.not(monthly_return: nil)
                      .order(:period)
                      .pluck(:monthly_return)

    compounded = prior_returns.reduce(BigDecimal("1")) do |acc, r|
      acc * (1 + r / 100)
    end

    compounded *= (1 + current_monthly_return / 100)

    (compounded - 1) * 100
  end

  # == calculate_last_12_months_return
  #
  # @author Moisés Reis
  #
  # Compounds the stored monthly_return values for the trailing 12-month window,
  # including the current month being persisted.
  #
  # Returns:: - The trailing-12-month percentage return as a BigDecimal, or nil
  #             if fewer than 12 months of data are available.
  def calculate_last_12_months_return(performance, current_monthly_return)
    return nil if current_monthly_return.nil?

    window_start = performance.period - 12.months + 1.day

    prior_returns = PerformanceHistory
                      .where(fund_investment_id: performance.fund_investment_id)
                      .where("period >= ? AND period < ?", window_start, performance.period)
                      .where.not(monthly_return: nil)
                      .order(:period)
                      .pluck(:monthly_return)

    return nil if prior_returns.size < 11

    compounded = prior_returns.reduce(BigDecimal("1")) do |acc, r|
      acc * (1 + r / 100)
    end

    compounded *= (1 + current_monthly_return / 100)

    (compounded - 1) * 100
  end

  # == find_quota_value
  #
  # @author Moisés Reis
  #
  # Attempts to retrieve the quota value for a fund on a specific date,
  # checking up to 5 previous days if the exact date is unavailable.
  #
  # Returns:: - The quota value or nil if no data is found.
  def find_quota_value(cnpj, target_date)
    5.times do |offset|
      valuation = FundValuation.find_by(fund_cnpj: cnpj, date: target_date - offset.days)
      return valuation.quota_value if valuation
    end
    nil
  end

  # == percentage
  #
  # @author Moisés Reis
  #
  # Safe division helper that returns nil on a zero or nil denominator.
  #
  # Returns:: - The resulting percentage value as a BigDecimal.
  def percentage(delta, base)
    return nil if base.nil? || base.zero?
    (BigDecimal(delta.to_s) / BigDecimal(base.to_s)) * 100
  end
end
