# app/queries/portfolios/benchmark_comparison_series_query.rb
#
# Builds a multi-series dataset comparing the portfolio's cumulative return
# against its relevant benchmark indices over time.
#
# Each series is expressed as a cumulative growth index rebased to 0%
# (i.e. +5.2 means +5.2% since the first available period), suitable
# for Chartkick line charts.
#
# DATA SOURCES:
#   - Portfolio returns  → performance_histories.monthly_return (aggregated via TWR)
#   - Benchmark returns  → economic_index_histories.value
#
# SERIES SELECTION:
#   The query includes every economic index that has at least one history
#   record overlapping the portfolio's performance window, capped at
#   MAX_BENCHMARKS to keep the chart readable.
#
# RETURN FORMAT (Chartkick-compatible):
#   [
#     { name: "Carteira",  data: { "Jan/25" => 0.0, "Fev/25" => 1.23, ... } },
#     { name: "CDI",       data: { "Jan/25" => 0.0, "Fev/25" => 0.98, ... } },
#     { name: "IBOVESPA",  data: { ... } },
#     ...
#   ]
#
# @author Project Team
module Portfolios
  class BenchmarkComparisonSeriesQuery

    MAX_BENCHMARKS = 5

    # @param portfolio      [Portfolio]
    # @param reference_date [Date]
    # @return [Array<Hash>]
    def self.call(portfolio, reference_date)
      new(portfolio, reference_date).call
    end

    def initialize(portfolio, reference_date)
      @portfolio      = portfolio
      @reference_date = reference_date
    end

    def call
      return [] if periods.empty?

      [portfolio_series] + benchmark_series_list
    end

    # =============================================================
    #                         PRIVATE
    # =============================================================

    private

    # ── date window ──────────────────────────────────────────────

    def periods
      @periods ||= PerformanceHistory
        .where(portfolio: @portfolio)
        .where(period: ..@reference_date)
        .order(:period)
        .pluck(:period)
        .uniq
    end

    def start_date
      @start_date ||= periods.first
    end

    def end_date
      @end_date ||= periods.last
    end

    # ── portfolio series ─────────────────────────────────────────

    # Aggregates all fund monthly returns into a single portfolio return
    # using a simple earnings-weighted approach, then cumulates.
    def portfolio_monthly_returns
      @portfolio_monthly_returns ||= begin
        rows = PerformanceHistory
          .where(portfolio: @portfolio)
          .where(period: start_date..end_date)
          .order(:period)
          .pluck(:period, :monthly_return, :earnings, :initial_balance)

        # Group by period and compute a portfolio-level return via
        # weighted average (weight = initial_balance when available,
        # otherwise equal-weight fallback).
        rows.group_by { |period, *| period }.transform_values do |group|
          total_balance = group.sum { |_, _, _, ib| ib.to_f }

          if total_balance > 0
            group.sum { |_, ret, _, ib| ret.to_f * ib.to_f } / total_balance
          else
            # Equal-weight fallback (e.g. first period with zero initial_balance)
            returns = group.map { |_, ret, *| ret.to_f }
            returns.sum / returns.size
          end
        end
      end
    end

    def portfolio_series
      {
        name: "Carteira",
        data: cumulate(portfolio_monthly_returns)
      }
    end

    # ── benchmark series ─────────────────────────────────────────

    def relevant_indices
      @relevant_indices ||= EconomicIndex
        .joins(:economic_index_histories)
        .where(economic_index_histories: { date: start_date..end_date })
        .distinct
        .limit(MAX_BENCHMARKS)
    end

    def benchmark_series_list
      relevant_indices.filter_map do |index|
        monthly = EconomicIndexHistory
          .where(economic_index_id: index.id)
          .where(date: start_date..end_date)
          .order(:date)
          .pluck(:date, :value)
          .to_h { |date, val| [date, val.to_f] }

        next if monthly.empty?

        {
          name: index.abbreviation,
          data: cumulate(monthly)
        }
      end
    end

    # ── cumulation helper ─────────────────────────────────────────

    # Converts a Hash of { Date => monthly_return_pct } into a cumulative
    # growth series rebased to 0 at the first period.
    #
    # Formula: cumulative[t] = (1 + r1/100) * (1 + r2/100) * … * (1 + rt/100) - 1
    # Result is expressed as percentage points (×100).
    #
    # @param monthly_returns [Hash<Date, Float>] keyed by period date
    # @return [Hash<String, Float>] keyed by formatted label "Mmm/YY"
    def cumulate(monthly_returns)
      cumulative = 1.0
      monthly_returns
        .sort
        .each_with_object({}) do |(date, ret), acc|
          cumulative *= (1 + ret / 100.0)
          acc[format_period(date)] = ((cumulative - 1) * 100).round(4)
        end
    end

    def format_period(date)
      I18n.l(date.to_date, format: "%b/%y").capitalize
    rescue
      date.to_date.strftime("%b/%y")
    end
  end
end