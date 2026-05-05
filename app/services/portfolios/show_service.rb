# app/services/portfolios/show_service.rb
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
      keyword_init: true
    )

    private_class_method :new

    # =============================================================
    #                      2. PUBLIC INTERFACE
    # =============================================================

    # @param portfolio      [Portfolio]
    # @param reference_date [Date]
    # @return [Result]
    def self.call(portfolio, reference_date:)
      new(portfolio, reference_date).send(:call)
    end

    # =============================================================
    #                       3. INITIALIZATION
    # =============================================================

    def initialize(portfolio, reference_date)
      @portfolio      = portfolio
      @reference_date = reference_date
    end

    # =============================================================
    #                        4. EXECUTION
    # =============================================================

    private

    def call
      fund_investments   = @portfolio.fund_investments
                                     .includes(:investment_fund, :applications, :redemptions)

      reference_period, recent_performance = Portfolios::RecentPerformanceQuery.call(
        @portfolio, @reference_date
      )

      performance_by_fund = recent_performance.index_by(&:fund_investment_id)
      recent_performance  = recent_performance.order("monthly_return DESC")

      returns = Portfolios::PerformanceReturnsCalculator.call(
        recent_performance, @reference_date
      )

      benchmark_series, portfolio_yield_series, benchmark_label =
        Portfolios::BenchmarkSeriesQuery.call(@portfolio, @reference_date)

      Result.new(
        portfolio:                @portfolio,
        reference_date:           @reference_date,
        reference_period:         reference_period,
        allocation_data:          Portfolios::AllocationDataQuery.call(fund_investments),
        institution_distribution: Portfolios::InstitutionDistributionQuery.call(fund_investments),
        indices_data:             Portfolios::IndicesAllocationQuery.call(@portfolio),
        normative_data:           Portfolios::NormativeAllocationQuery.call(@portfolio),
        monthly_flows:            Portfolios::MonthlyFlowsQuery.call(@portfolio),
        equity_evolution:         @portfolio.value_timeline(12),
        monthly_earnings_history: @portfolio.monthly_earnings_history,
        recent_performance:       recent_performance,
        performance_by_fund:      performance_by_fund,
        total_market_value:       fund_investments.sum { |fi| fi.current_market_value_on(@reference_date) },
        total_earnings:           returns.total_earnings,
        portfolio_return:         returns.portfolio_return,
        portfolio_12m_return:     returns.portfolio_12m_return,
        portfolio_yearly_return:  @portfolio.portfolio_yearly_return_percentage(reference_period),
        portfolio_monthly_twr:    @portfolio.portfolio_twr_return_on(
                                    @reference_date.beginning_of_month - 1.day, @reference_date
                                  ),
        portfolio_yearly_twr:     @portfolio.portfolio_twr_return_on(
                                    @reference_date.beginning_of_year - 1.day, @reference_date
                                  ),
        benchmark_series:         benchmark_series,
        portfolio_yield_series:   portfolio_yield_series,
        current_benchmark_label:  benchmark_label,
        compliance_report:        Portfolios::ComplianceReportQuery.call(
                                    @portfolio, Portfolios::NormativeAllocationQuery.call(@portfolio)
                                  ),
        drawdown_series:          Portfolios::DrawdownCalculator.call(portfolio_yield_series),
        recent_applications:      Portfolios::RecentApplicationsQuery.call(@portfolio),
        recent_redemptions:       Portfolios::RecentRedemptionsQuery.call(@portfolio),
        new_application:          Application.new,
        new_redemption:           Redemption.new
      )
    end
  end
end