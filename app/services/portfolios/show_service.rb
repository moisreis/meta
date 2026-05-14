# Assembles all data required to render the portfolio analytics dashboard.
#
# Orchestrates every query, calculator, and builder needed for a given
# portfolio and reference date, returning a fully-populated {Result}
# struct. Callers receive a single value object and are not concerned
# with how individual fields are computed.
#
# Follows the Result + thin-call pattern: {.call} is the only public
# entry point; all computation is isolated in private methods.
#
# @author <Team>
#
# TABLE OF CONTENTS:
#   1.  Result
#   2.  Public Interface
#   3.  Initialization
#   4.  Execution
#   5.  Memoized Intermediates
#       5a. Recent Performance
#       5b. Returns
#       5c. Benchmark Series
#       5d. Normative Allocation
#       5e. Time-Weighted Returns
#   6.  Result Field Builders
#       6a. Performance Fields
#       6b. Benchmark Fields
#       6c. Allocation Fields
#       6d. Financial Fields
#       6e. Flow Fields
#       6f. Fund Fields
#       6g. Compliance Fields
#       6h. Transaction Fields
module Portfolios
  class ShowService

    # =============================================================
    #                          1. RESULT
    # =============================================================

    Result = Struct.new(
      :portfolio,
      :reference_date,
      :reference_period,
      :allocation_data,
      :institution_distribution,
      :indices_data,
      :normative_data,
      :monthly_flows,
      :equity_evolution,
      :monthly_earnings_history,
      :recent_performance,
      :performance_by_fund,
      :total_market_value,
      :total_earnings,
      :monthly_total_earnings,
      :portfolio_return,
      :portfolio_12m_return,
      :portfolio_yearly_return,
      :portfolio_monthly_twr,
      :portfolio_yearly_twr,
      :benchmark_series,
      :portfolio_yield_series,
      :current_benchmark_label,
      :compliance_report,
      :drawdown_series,
      :recent_applications,
      :recent_redemptions,
      :new_application,
      :new_redemption,
      :yearly_earnings,
      :fund_investments,
      :net_movement_by_fund,
      :fund_quota_value,
      :market_value_by_fund,
      :normative_articles,
      :benchmark_deviation_by_pna,
      :benchmark_comparison_series,
      :checking_accounts,
      keyword_init: true
    )

    private_class_method :new

    # =============================================================
    #                      2. PUBLIC INTERFACE
    # =============================================================

    # Assembles and returns the complete dashboard result for the
    # given portfolio and reference date.
    #
    # @param portfolio      [Portfolio] The portfolio to report on.
    # @param reference_date [Date]      The date used for snapshots and calculations.
    # @return               [Result]    A fully-populated, read-only result struct.
    def self.call(portfolio, reference_date:)
      new(portfolio, reference_date).send(:call)
    end

    # =============================================================
    #                       3. INITIALIZATION
    # =============================================================

    # @param portfolio      [Portfolio]
    # @param reference_date [Date]
    def initialize(portfolio, reference_date)
      @portfolio      = portfolio
      @reference_date = reference_date
    end

    # =============================================================
    #                        4. EXECUTION
    # =============================================================

    private

    # Builds and returns the complete {Result} struct by delegating
    # each logical group of fields to a dedicated builder method.
    def call
      Result.new(
        portfolio:        @portfolio,
        reference_date:   @reference_date,
        reference_period: reference_period,
        new_application:  Application.new,
        new_redemption:   Redemption.new,
        **performance_fields,
        **benchmark_fields,
        **allocation_fields,
        **financial_fields,
        **flow_fields,
        **fund_fields,
        **compliance_fields,
        **transaction_fields
      )
    end

    # =============================================================
    #               5. MEMOIZED INTERMEDIATES
    # =============================================================

    # ---  5a. RECENT PERFORMANCE  --------------------------------

    # Caches the raw two-element result from {RecentPerformanceQuery}
    # so that {#reference_period} and {#recent_performance} share
    # a single query execution.
    def performance_query_result
      @performance_query_result ||= Portfolios::RecentPerformanceQuery.call(
        @portfolio, @reference_date
      )
    end

    # The monthly reporting period derived from recent performance data.
    #
    # @return [Date]
    def reference_period
      performance_query_result.first
    end

    # The ordered recent-performance relation for the reference date.
    # Sorted by monthly return descending.
    #
    # @return [ActiveRecord::Relation]
    def recent_performance
      @recent_performance ||= performance_query_result.last.order("monthly_return DESC")
    end

    # ---  5b. RETURNS  -------------------------------------------

    # Aggregated return metrics for the current reference date.
    # Computed once and shared across all financial field builders.
    #
    # @return [Portfolios::PerformanceReturnsCalculator::Result]
    def returns
      @returns ||= Portfolios::PerformanceReturnsCalculator.call(
        recent_performance, @reference_date
      )
    end

    # ---  5c. BENCHMARK SERIES  ----------------------------------

    # Caches the raw three-element result from {BenchmarkSeriesQuery}
    # so that {#benchmark_series}, {#portfolio_yield_series}, and
    # {#benchmark_label} share a single query execution.
    def benchmark_series_result
      @benchmark_series_result ||= Portfolios::BenchmarkSeriesQuery.call(
        @portfolio, @reference_date
      )
    end

    # @return [Array]
    def benchmark_series
      benchmark_series_result[0]
    end

    # @return [Array]
    def portfolio_yield_series
      benchmark_series_result[1]
    end

    # @return [String]
    def benchmark_label
      benchmark_series_result[2]
    end

    # ---  5d. NORMATIVE ALLOCATION  ------------------------------

    # Cached normative allocation data shared by {#allocation_fields}
    # and {#compliance_fields} to avoid executing the query twice.
    #
    # @return [Object]
    def normative_alloc
      @normative_alloc ||= Portfolios::NormativeAllocationQuery.call(@portfolio)
    end

    # ---  5e. TIME-WEIGHTED RETURNS  -----------------------------

    # Monthly TWR from the first day of the reference month to the reference date.
    #
    # @return [Numeric]
    def monthly_twr
      @monthly_twr ||= Portfolios::TwrCalculator.call(
        @portfolio,
        start_date: @reference_date.beginning_of_month - 1.day,
        end_date:   @reference_date
      )
    end

    # Year-to-date TWR from the first day of the reference year to the reference date.
    #
    # @return [Numeric]
    def yearly_twr
      @yearly_twr ||= Portfolios::TwrCalculator.call(
        @portfolio,
        start_date: @reference_date.beginning_of_year - 1.day,
        end_date:   @reference_date
      )
    end

    # =============================================================
    #               6. RESULT FIELD BUILDERS
    # =============================================================

    # ---  6a. PERFORMANCE FIELDS  --------------------------------

    # Returns recent performance and a fund-keyed lookup index.
    #
    # @return [Hash]
    def performance_fields
      {
        recent_performance:  recent_performance,
        performance_by_fund: recent_performance.index_by(&:fund_investment_id)
      }
    end

    # ---  6b. BENCHMARK FIELDS  ----------------------------------

    # Returns all benchmark comparison and deviation data.
    #
    # @return [Hash]
    def benchmark_fields
      {
        benchmark_series:            benchmark_series,
        portfolio_yield_series:      portfolio_yield_series,
        current_benchmark_label:     benchmark_label,
        drawdown_series:             Portfolios::DrawdownCalculator.call(portfolio_yield_series),
        benchmark_deviation_by_pna:  Portfolios::BenchmarkDeviationQuery.call(@portfolio),
        benchmark_comparison_series: Portfolios::BenchmarkComparisonSeriesQuery.call(
                                       @portfolio, @reference_date
                                     )
      }
    end

    # ---  6c. ALLOCATION FIELDS  ---------------------------------

    # Returns portfolio composition breakdowns by fund, institution,
    # index, and normative category.
    #
    # @return [Hash]
    def allocation_fields
      {
        allocation_data:          Portfolios::AllocationDataQuery.call(@portfolio),
        institution_distribution: Portfolios::InstitutionDistributionQuery.call(@portfolio),
        indices_data:             Portfolios::IndicesAllocationQuery.call(@portfolio),
        normative_data:           normative_alloc
      }
    end

    # ---  6d. FINANCIAL FIELDS  ----------------------------------

    # Returns all monetary totals, return percentages, and TWR values.
    #
    # @return [Hash]
    def financial_fields
      {
        total_market_value:      Portfolios::TotalMarketValueQuery.call(@portfolio, @reference_date),
        total_earnings:          returns.total_earnings,
        monthly_total_earnings:  Portfolios::TotalEarningsQuery.call(@portfolio, @reference_date),
        portfolio_return:        returns.portfolio_return,
        portfolio_12m_return:    returns.portfolio_12m_return,
        portfolio_yearly_return: Portfolios::YearlyReturnCalculator.call(
          @portfolio,
          reference_date: reference_period
        ),
        portfolio_monthly_twr:   monthly_twr,
        portfolio_yearly_twr:    yearly_twr,
        yearly_earnings:         Portfolios::YearlyEarningsQuery.new(@portfolio, @reference_date).call
      }
    end

    # ---  6e. FLOW FIELDS  ---------------------------------------

    # Returns time-series data for cash flows, equity, and earnings history.
    #
    # @return [Hash]
    def flow_fields
      {
        monthly_flows:            Portfolios::MonthlyFlowsQuery.call(@portfolio),
        equity_evolution:         Portfolios::ValueTimelineCalculator.call(
                                    @portfolio, months_back: 12
                                  ),
        monthly_earnings_history: Portfolios::MonthlyEarningsChartDataBuilder.call(
                                    Portfolios::MonthlyEarningsHistoryQuery.call(@portfolio)
                                  )
      }
    end

    # ---  6f. FUND FIELDS  ---------------------------------------

    # Returns per-fund snapshots: quota values, market values, and net movement.
    #
    # @return [Hash]
    def fund_fields
      {
        fund_investments:     Portfolios::FundInvestmentsQuery.call(@portfolio),
        net_movement_by_fund: Portfolios::NetMovementQuery.call(@portfolio, @reference_date),
        fund_quota_value:     Portfolios::FundQuotaValueQuery.call(@portfolio, @reference_date),
        market_value_by_fund: Portfolios::MarketValueByFundQuery.call(@portfolio, @reference_date)
      }
    end

    # ---  6g. COMPLIANCE FIELDS  ---------------------------------

    # Returns the compliance report and normative articles.
    # Reuses {#normative_alloc} to avoid a duplicate query.
    #
    # @return [Hash]
    def compliance_fields
      {
        compliance_report: Portfolios::ComplianceReportQuery.call(@portfolio, normative_alloc),
        normative_articles: Portfolios::NormativeArticlesQuery.call(@portfolio)
      }
    end

    # ---  6h. TRANSACTION FIELDS  --------------------------------

    # Returns recent applications, redemptions, and checking accounts.
    #
    # @return [Hash]
    def transaction_fields
      {
        recent_applications: Portfolios::RecentApplicationsQuery.call(@portfolio),
        recent_redemptions:  Portfolios::RecentRedemptionsQuery.call(@portfolio),
        checking_accounts:   Portfolios::CheckingAccountsQuery.call(@portfolio)
      }
    end

  end
end
