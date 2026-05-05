# app/queries/portfolios/benchmark_series_query.rb
#
# Builds the cumulative benchmark and portfolio yield series for the current
# year up to the reference date, used for the performance comparison chart.
#
# @return [Array(Array, Array, String)]
#   [benchmark_series, portfolio_yield_series, benchmark_label]
module Portfolios
  class BenchmarkSeriesQuery
    def self.call(portfolio, reference_date)
      new(portfolio, reference_date).call
    end

    def initialize(portfolio, reference_date)
      @portfolio      = portfolio
      @reference_date = reference_date
    end

    def call
      [benchmark_series, portfolio_yield_series, benchmark_label]
    end

    private

    def target_index
      @target_index ||= begin
        name = @portfolio.fund_investments
                         .joins(:investment_fund)
                         .group("investment_funds.benchmark_index")
                         .order("count_all DESC")
                         .count
                         .keys.first || "CDI"
        EconomicIndex.find_by(abbreviation: name)
      end
    end

    def benchmark_label
      target_index&.name || "Benchmark"
    end

    def benchmark_series
      return [] unless target_index

      cumulative = BigDecimal("1.0")
      target_index.economic_index_histories
                  .where(date: @reference_date.beginning_of_year..@reference_date)
                  .order(:date)
                  .map do |h|
        cumulative *= (1 + (h.value || 0) / BigDecimal("100"))
        [I18n.l(h.date, format: "%b/%y"), ((cumulative - 1) * 100).to_f.round(2)]
      end
    end

    def portfolio_yield_series
      cumulative = BigDecimal("1.0")
      @portfolio.performance_histories
                .where(period: @reference_date.beginning_of_year..@reference_date)
                .select("period, SUM(earnings) as total_earnings, SUM(initial_balance) as total_balance")
                .group(:period)
                .order(:period)
                .filter_map do |hist|
        next unless hist.total_balance.to_f > 0
        cumulative *= (1 + hist.total_earnings / hist.total_balance)
        [I18n.l(hist.period, format: "%b/%y"), ((cumulative - 1) * 100).to_f.round(2)]
      end
    end
  end
end