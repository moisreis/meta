# frozen_string_literal: true

# = PortfolioMonthlyReportGenerator
#
# Generates a paginated monthly investment portfolio report in PDF format
# using the Prawn library. The report covers performance metrics, fund
# allocations, benchmark comparisons, normative policy compliance, and
# historical data across a rolling 12-month window.
#
# == Usage
#
#   generator = PortfolioMonthlyReportGenerator.new(portfolio, Date.current.end_of_month)
#   pdf_bytes = generator.generate
#   File.binwrite("report.pdf", pdf_bytes)
#
# == Dependencies
#
# * +prawn+ — PDF generation
# * +prawn/table+ — table rendering within Prawn
# * +bigdecimal+ — precision arithmetic for financial calculations
# * Custom TrueType fonts stored under +app/assets/fonts/+
#
# == Page Structure
#
# 1.  Cover page                    — key metrics summary
# 2.  Portfolio performance         — monthly/yearly returns + benchmarks
# 3.  Fund details                  — per-fund breakdown + checking accounts
# 4.  Monthly history               — patrimony evolution + cash flows
# 5.  Fund distribution             — allocation bars + donut charts
# 6.  Distribution donuts           — by benchmark index and normative category
# 7.  Earnings by index             — rendimento per reference index
# 8.  Index patrimony               — patrimony per reference index
# 9.  Historical table              — 12-month tabular history
# 10. Asset type page               — patrimony and earnings by asset category
# 11. Accumulated indices           — YTD benchmark comparison
# 12. Investment policy (x2)        — normative compliance charts
#
# @author Moisés Reis
# @since  2024
class PortfolioMonthlyReportGenerator
  require 'prawn'
  require 'prawn/table'
  require 'bigdecimal'

  # ---------------------------------------------------------------------------
  # Constants
  # ---------------------------------------------------------------------------

  # Flat color palette used throughout all charts and tables.
  # Values are hex strings without the leading +#+ (Prawn convention).
  #
  # The +:chart+ key is an ordered array of distinct colors assigned to
  # series/slices in the order they are rendered.
  C = {
    primary: '4faaa0',
    secondary: '609ed2',
    body: '333333',
    muted: '8a8a8a',
    accent: 'f9f9f9',
    success: '30b757',
    danger: 'f3404a',
    warning: 'f6a10a',
    gray_dark: '333333',
    gray: '8a8a8a',
    gray_light: '8a8a8a',
    bg_light: 'f9f9f9',
    bg_blue: 'eefdfc',
    white: 'ffffff',
    border: 'f2f2f5',
    transparent: '0000',
    chart: %w[
      8fe3d6 56d279 fb6e76 7eb7dc 34cfdc 7a7be0
      7c86ff a3e500 00d5be d8db00 b09bea 73b1e7
    ]
  }.freeze

  # A4 portrait page dimensions in points (1 pt = 1/72 inch).
  PAGE_W = 595.28
  PAGE_H = 841.89

  # Vertical margins in points.
  MARGIN_T = 40
  MARGIN_B = 70

  # Horizontal margin applied to both left and right sides.
  MARGIN_LR = 40

  # Usable content width derived from page width minus both horizontal margins.
  CONTENT_W = PAGE_W - MARGIN_LR * 2

  # Company contact and identification details printed in the footer/cover.
  PHONE = '(74) 981-399-579'
  EMAIL = 'mr.investing@outlook.com'
  SITE = 'www.investingmeta.com.br'
  COMPANY = 'META CONSULTORIA DE INVESTIMENTOS INSTITUCIONAIS'
  CNPJ = '34.369.665/0001-99'

  # Absolute path to the watermark image applied to every page after the cover.
  WATERMARK_IMAGE_PATH = Rails.root.join('app', 'assets', 'images', 'logo.png').freeze

  # Rendered width (points) of the watermark image.
  WATERMARK_WIDTH = 380

  # Maps the exact +abbreviation+ strings stored in +EconomicIndex+ records to
  # the symbolic keys used internally by this generator. Centralised here so
  # that a typo in one place does not silently suppress an entire series.
  BENCHMARK_KEY_MAP = {
    'CDI' => :cdi,
    'IPCA' => :ipca,
    'IMAGERAL' => :ima_geral,
    'IBOVESPA' => :ibovespa
  }.freeze

  # ---------------------------------------------------------------------------
  # Public interface
  # ---------------------------------------------------------------------------

  # @return [Portfolio] the portfolio being reported on
  attr_reader :portfolio

  # @return [Date] the reference end-of-month date for the report
  attr_reader :reference_date

  # @return [Hash] the fully collected data hash (see {#collect_data})
  attr_reader :data

  # @return [Prawn::Document] the underlying Prawn document instance
  attr_reader :pdf

  # Initialises the generator, collects all required data, and builds the
  # Prawn document object. No PDF bytes are produced until {#generate} is
  # called.
  #
  # @param portfolio      [Portfolio] the portfolio record to report on
  # @param reference_date [Date]      end-of-month date used as the reporting
  #   period. Defaults to the last day of the current month. If no performance
  #   records exist for this date the generator automatically falls back to the
  #   most recent period that does have data and adjusts +@reference_date+
  #   accordingly.
  def initialize(portfolio, reference_date = Date.current.end_of_month)
    @portfolio = portfolio
    @reference_date = reference_date
    @requested_reference_date = reference_date.dup
    @performance_data = collect_performance_data
    @data = collect_data
    @pdf = Prawn::Document.new(
      page_size: 'A4',
      page_layout: :portrait,
      margin: [MARGIN_T, MARGIN_LR, MARGIN_B, MARGIN_LR]
    )
    configure_fonts
  end

  # Renders all report pages and returns the PDF as a binary string.
  #
  # The method orchestrates every page in a fixed order, stamps a global
  # footer and a translucent watermark on every non-cover page, then
  # delegates to +Prawn::Document#render+ for final serialisation.
  #
  # @return [String] binary PDF content ready to be written to disk or sent
  #   as an HTTP response
  def generate
    render_summary_page
    render_fund_details_page
    render_monthly_history_page
    render_fund_distribution_page
    render_index_earnings_page
    render_index_patrimony_page
    render_historical_table_page
    render_asset_type_page
    render_investment_policy_page
    render_accumulated_indices_page
    stamp_global_footer
    stamp_watermark
    pdf.render
  end

  private

  # ---------------------------------------------------------------------------
  # Font configuration
  # ---------------------------------------------------------------------------

  # Registers all custom TrueType font families with the Prawn document and
  # sets +Plus Jakarta Sans+ as the document default.
  #
  # @return [void]
  def configure_fonts
    pdf.font_families.update(
      'Source Serif 4' => {
        normal: Rails.root.join('app/assets/fonts/SourceSerif4-Regular.ttf'),
        bold: Rails.root.join('app/assets/fonts/SourceSerif4-Bold.ttf'),
        italic: Rails.root.join('app/assets/fonts/SourceSerif4-Italic.ttf')
      },
      'JetBrains Mono' => {
        normal: Rails.root.join('app/assets/fonts/JetBrainsMono-Regular.ttf'),
        bold: Rails.root.join('app/assets/fonts/JetBrainsMono-Bold.ttf')
      },
      'Plus Jakarta Sans' => {
        normal: Rails.root.join('app/assets/fonts/PlusJakartaSans-Regular.ttf'),
        bold: Rails.root.join('app/assets/fonts/PlusJakartaSans-Bold.ttf'),
        italic: Rails.root.join('app/assets/fonts/PlusJakartaSans-Italic.ttf')
      },
      'IBM Plex Mono' => {
        normal: Rails.root.join('app/assets/fonts/IBMPlexMono-Regular.ttf'),
        bold: Rails.root.join('app/assets/fonts/IBMPlexMono-Bold.ttf'),
        italic: Rails.root.join('app/assets/fonts/IBMPlexMono-Italic.ttf')
      },
      'Geist Mono' => {
        normal: Rails.root.join('app/assets/fonts/GeistMono-Regular.ttf'),
        bold: Rails.root.join('app/assets/fonts/GeistMono-Semibold.ttf')
      },
      'Geist' => {
        normal: Rails.root.join('app/assets/fonts/Geist-Regular.ttf'),
        bold: Rails.root.join('app/assets/fonts/Geist-Semibold.ttf')
      },
      'Geist Pixel Square' => {
        normal: Rails.root.join('app/assets/fonts/GeistPixel-Square.ttf')
      }
    )
    pdf.font 'Plus Jakarta Sans'
  end

  # ---------------------------------------------------------------------------
  # Data collection
  # ---------------------------------------------------------------------------

  # Builds and returns the central data hash consumed by all page renderers.
  #
  # Each key is a stable interface; callers access data via +data[:key]+.
  #
  # @return [Hash] with the following keys:
  #   * +:fund_investments+    [ActiveRecord::AssociationRelation]
  #   * +:performance+         [Hash] — see {#collect_performance_data}
  #   * +:benchmarks+          [Hash] — see {#collect_benchmark_data}
  #   * +:monthly_history+     [Array<Hash>] — see {#collect_monthly_history}
  #   * +:monthly_flows+       [Array<Hash>] — see {#collect_monthly_flows}
  #   * +:allocation+          [Array<Hash>] — see {#calculate_allocation_data}
  #   * +:article_groups+      [Hash]
  #   * +:index_groups+        [Hash]
  #   * +:institution_groups+  [Hash]
  #   * +:asset_type_groups+   [Hash]
  #   * +:economic_indices+    [Hash]
  #   * +:investment_policy+   [Array<Hash>]
  #   * +:policy_compliance+   [Hash]
  #   * +:checking_accounts+   [Array<Hash>]
  def collect_data
    {
      fund_investments: fund_investments_with_data,
      portfolio_normative: collect_portfolio_normative_data,
      performance: @performance_data,
      benchmarks: collect_benchmark_data,
      monthly_history: collect_monthly_history,
      monthly_flows: collect_monthly_flows,
      allocation: calculate_allocation_data,
      article_groups: calculate_article_groups,
      index_groups: calculate_index_groups,
      institution_groups: calculate_institution_groups,
      asset_type_groups: calculate_asset_type_groups,
      economic_indices: collect_economic_indices_history,
      investment_policy: collect_investment_policy_data,
      policy_compliance: calculate_policy_compliance,
      checking_accounts: collect_checking_accounts
    }
  end

  # Returns the portfolio's fund investments with all associations required
  # by the report preloaded to prevent N+1 queries.
  #
  # @return [ActiveRecord::AssociationRelation<FundInvestment>]
  def fund_investments_with_data
    @portfolio.fund_investments
              .includes(
                :investment_fund,
                investment_fund: { investment_fund_articles: :normative_article }
              )
  end

  # Collects and computes all performance metrics for the reporting period.
  #
  # If no +PerformanceHistory+ records exist for +@reference_date+, the method
  # falls back to the most recent period available and updates +@reference_date+
  # in place so that all subsequent data collectors use the same consistent
  # period.
  #
  # Weighted returns are calculated using each fund investment's
  # +percentage_allocation+ as the weight, following a simple weighted-mean
  # formula.
  #
  # Yearly earnings accumulate prior-month +earnings+ from the database plus
  # the current +total_gain+ (mark-to-market), except in January where the
  # current gain equals the full year-to-date figure.
  #
  # @return [Hash] with the following keys:
  #   * +:monthly_return+  [Float] weighted average monthly return (%)
  #   * +:yearly_return+   [Float] weighted average YTD return (%)
  #   * +:total_earnings+  [Float] current-month earnings in currency
  #   * +:yearly_earnings+ [Float] year-to-date earnings in currency
  #   * +:total_value+     [Float] current total market value in currency
  #   * +:initial_balance+ [Float] sum of initial balances for the period
  #   * +:performances+    [Array<PerformanceHistory>] raw records
  def collect_performance_data
    performances = @portfolio.performance_histories
                             .where(period: @reference_date)
                             .includes(fund_investment: :investment_fund)

    if performances.empty?
      latest = @portfolio.performance_histories.maximum(:period)
      return empty_performance if latest.nil?

      @reference_date = latest
      performances = @portfolio.performance_histories
                               .where(period: latest)
                               .includes(fund_investment: :investment_fund)
    end

    monthly_return = @portfolio.portfolio_twr_return_on(
      @reference_date.beginning_of_month - 1.day,
      @reference_date
    )
    yearly_return = @portfolio.portfolio_twr_return_on(
      @reference_date.beginning_of_year - 1.day,
      @reference_date
    )
    total_earnings = @portfolio.total_earnings_on(@reference_date)
    yearly_earnings = @portfolio.yearly_earnings(@reference_date)

    total_value = @portfolio.fund_investments
                            .includes(:investment_fund, :applications, :redemptions)
                            .sum { |fi| fi.current_market_value_on(@reference_date) }

    total_initial = performances.sum(:initial_balance).to_f

    {
      monthly_return: monthly_return.to_f,
      yearly_return: yearly_return.to_f,
      total_earnings: total_earnings.to_f,
      yearly_earnings: yearly_earnings.to_f,
      total_value: total_value.to_f,
      initial_balance: total_initial,
      performances: performances
    }
  end

  # Builds the portfolio-to-article comparison data from
  # +PortfolioNormativeArticle+.
  #
  # Each entry holds both the portfolio-side targets and the article-side
  # targets so the PDF page can display them side by side and evaluate
  # compliance.
  #
  # Compliance is defined as: the portfolio +benchmark_target+ falls within
  # the article's +minimum_target+..+maximum_target+ range. If either bound
  # is absent the check is skipped and the row is marked compliant.
  #
  # @return [Array<Hash>] each element has:
  #   * +:display_name+          [String]
  #   * +:article_benchmark+     [Float, nil]
  #   * +:portfolio_benchmark+   [Float, nil]
  #   * +:deviation+             [Float, nil]
  #   * +:article_minimum+       [Float, nil]
  #   * +:portfolio_minimum+     [Float, nil]
  #   * +:article_maximum+       [Float, nil]
  #   * +:portfolio_maximum+     [Float, nil]
  #   * +:compliant+             [Boolean]
  def collect_portfolio_normative_data
    active_fi_ids = (@performance_data[:performances] || [])
                      .select { |p| p.earnings.to_f != 0 || p.initial_balance.to_f > 0 }
                      .map(&:fund_investment_id)
                      .to_set

    perf_by_fi = (@performance_data[:performances] || [])
                   .each_with_object({}) { |p, h| h[p.fund_investment_id] = p }

    total_initial = perf_by_fi.values.sum { |p| p.initial_balance.to_f }

    alloc_by_article = Hash.new(0.0)
    @portfolio.fund_investments
              .includes(investment_fund: { investment_fund_articles: :normative_article })
              .select { |fi| active_fi_ids.include?(fi.id) }
              .each do |fi|
      perf = perf_by_fi[fi.id]
      next unless perf && perf.initial_balance.to_f > 0

      weight = total_initial > 0 ? (perf.initial_balance.to_f / total_initial * 100) : 0.0
      articles = fi.investment_fund.investment_fund_articles.select(&:normative_article)
      next if articles.empty?

      articles.each do |ifa|
        alloc_by_article[ifa.normative_article.id] += weight / articles.size
      end
    end

    # --- MUDANÇA PRINCIPAL ---
    # Coleta todos os artigos normativos presentes nos fundos ativos,
    # independente de estarem em portfolio_normative_articles
    pna_by_article_id = @portfolio
                          .portfolio_normative_articles
                          .includes(:normative_article)
                          .each_with_object({}) { |pna, h| h[pna.normative_article_id] = pna }

    # União: artigos do portfolio_normative_articles + artigos vindos dos fundos ativos
    article_ids_from_funds = alloc_by_article.keys
    all_article_ids = (pna_by_article_id.keys + article_ids_from_funds).uniq

    NormativeArticle
      .where(id: all_article_ids)
      .map do |art|
      pna = pna_by_article_id[art.id]

      art_bench = art.benchmark_target&.to_f
      prt_bench = pna&.benchmark_target&.to_f
      art_min   = art.minimum_target&.to_f
      art_max   = art.maximum_target&.to_f
      prt_min   = pna&.minimum_target&.to_f
      prt_max   = pna&.maximum_target&.to_f

      carteira_atual = alloc_by_article[art.id].round(4)

      deviation = (prt_bench && art_bench) ? (prt_bench - art_bench).round(4) : nil

      compliant = if prt_min && prt_max && prt_max > 0
                    carteira_atual >= prt_min && carteira_atual <= prt_max
                  elsif prt_min
                    carteira_atual >= prt_min
                  elsif prt_max
                    carteira_atual <= prt_max
                  else
                    true
                  end

      {
        display_name:        art.display_name,
        carteira_atual:      carteira_atual,
        article_benchmark:   art_bench,
        portfolio_benchmark: prt_bench,
        deviation:           deviation,
        article_minimum:     art_min,
        portfolio_minimum:   prt_min,
        article_maximum:     art_max,
        portfolio_maximum:   prt_max,
        compliant:           compliant
      }
    end.sort_by { |r| -r[:carteira_atual] }
  rescue StandardError => e
    Rails.logger.error("[collect_portfolio_normative_data] #{e.message}")
    []
  end

  # Returns a zeroed-out performance hash used when no history records exist
  # at all.
  #
  # @return [Hash]
  def empty_performance
    {
      monthly_return: 0.0,
      yearly_return: 0.0,
      total_earnings: 0.0,
      yearly_earnings: 0.0,
      total_value: 0.0,
      initial_balance: 0.0,
      performances: []
    }
  end

  # Fetches monthly and year-to-date values for each benchmark index defined
  # in {BENCHMARK_KEY_MAP}, then appends a computed +:meta+ key.
  #
  # META is defined as:
  #   META_monthly = annual_interest_rate + IPCA_monthly
  #   META_ytd     = annual_interest_rate + IPCA_ytd
  #
  # This reflects the portfolio's contractual performance target.
  #
  # YTD values are computed via geometric compounding rather than arithmetic
  # summation to accurately reflect cumulative return.
  #
  # @return [Hash{Symbol => Hash}] keys +:cdi+, +:ipca+, +:ima_geral+,
  #   +:ibovespa+, +:meta+; each value is +{ monthly: Float, ytd: Float }+
  def collect_benchmark_data
    indices = EconomicIndex.all.index_by(&:abbreviation)
    result = {}

    BENCHMARK_KEY_MAP.each do |abbr, key|
      idx = indices[abbr]
      monthly = 0.0
      ytd = 0.0

      if idx
        rec = idx.economic_index_histories
                 .where(date: @reference_date.beginning_of_month..@reference_date)
                 .order(date: :desc)
                 .first
        monthly = rec&.value.to_f

        monthly_values = idx.economic_index_histories
                            .where(date: @reference_date.beginning_of_year..@reference_date)
                            .order(date: :asc)
                            .pluck(:value)

        ytd = monthly_values.reduce(1.0) { |acc, v| acc * (1 + v.to_f / 100) }
        ytd = (ytd - 1) * 100
      end

      result[key] = { monthly: monthly, ytd: ytd }
    end

    ipca_idx = indices['IPCA']
    monthly_rate = @portfolio.annual_interest_rate.to_f

    meta_ytd = if ipca_idx
                 ipca_monthly_values = ipca_idx.economic_index_histories
                                               .where(date: @reference_date.beginning_of_year..@reference_date)
                                               .order(date: :asc)
                                               .pluck(:value)

                 ipca_monthly_values.reduce(1.0) do |acc, ipca_v|
                   acc * (1 + (monthly_rate + ipca_v.to_f) / 100)
                 end
               else
                 1.0
               end

    result[:meta] = {
      monthly: monthly_rate + result.dig(:ipca, :monthly).to_f,
      ytd: (meta_ytd - 1) * 100
    }

    %i[cdi ipca ima_geral ibovespa meta].each { |k| result[k] ||= { monthly: 0.0, ytd: 0.0 } }
    result

  rescue StandardError => e
    Rails.logger.error("Error collecting benchmark data: #{e.message}")
    %i[cdi ipca ima_geral ibovespa meta].each_with_object({}) { |k, h| h[k] = { monthly: 0.0, ytd: 0.0 } }
  end

  # Builds the 12-month patrimonial history used by bar charts and tables.
  #
  # The result always contains exactly 12 entries covering the rolling window
  # from +(reference_date - 11.months).beginning_of_month+ to
  # +reference_date+. Months without +PerformanceHistory+ records are
  # represented by zero-valued entries so charts display all 12 columns.
  #
  # The final entry (current month) has its +:earnings+ and +:balance+ values
  # overridden with live mark-to-market figures from the portfolio to ensure
  # accuracy.
  #
  # @return [Array<Hash>] each element has:
  #   * +:period+   [Date] the first day of the month
  #   * +:earnings+ [Float] total earnings for the month in currency
  #   * +:balance+  [Float] total patrimonial value at end of month
  def collect_monthly_history
    start_date = (@reference_date - 11.months).beginning_of_month

    rows = @portfolio.performance_histories
                     .where(period: start_date..@reference_date)
                     .group(:period)
                     .select('period, SUM(earnings) AS total_earnings, SUM(initial_balance) AS total_initial')
                     .order(period: :asc)
                     .map do |r|
      {
        period: r.period,
        earnings: r.total_earnings.to_f,
        balance: r.total_initial.to_f + r.total_earnings.to_f
      }
    end

    if rows.any? && rows.last[:period] == @reference_date
      rows.last[:earnings] = @portfolio.total_earnings_on(@reference_date).to_f
      rows.last[:balance] = @portfolio.fund_investments
                                      .includes(:investment_fund, :applications, :redemptions)
                                      .sum { |fi| fi.current_market_value_on(@reference_date) }.to_f
    end

    rows_by_month = rows.index_by { |r| r[:period].beginning_of_month }

    12.times.map do |i|
      period = (start_date + i.months).beginning_of_month
      rows_by_month[period] || { period: period, earnings: 0.0, balance: 0.0 }
    end
  end

  # Collects application and redemption totals for each of the 12 months in
  # the rolling window.
  #
  # Each month covers the full calendar interval from the 1st to the last day.
  # Months with no movements produce zero values, preserving the full 12-slot
  # series.
  #
  # @return [Array<Hash>] each element has:
  #   * +:period+       [Date] first day of the month
  #   * +:applications+ [Float] total application value in currency
  #   * +:redemptions+  [Float] total redemption value in currency
  def collect_monthly_flows
    start_date = (@reference_date - 11.months).beginning_of_month
    result = []

    12.times do |i|
      month_start = (start_date + i.months).beginning_of_month
      month_end = month_start.end_of_month

      apps = @portfolio.fund_investments
                       .joins(:applications)
                       .where(applications: { cotization_date: month_start..month_end })
                       .sum('applications.financial_value').to_f

      reds = @portfolio.fund_investments
                       .joins(:redemptions)
                       .where(redemptions: { cotization_date: month_start..month_end })
                       .sum('redemptions.redeemed_liquid_value').to_f

      result << { period: month_start, applications: apps, redemptions: reds }
    end

    result
  end

  # Builds the fund-level allocation array used to render horizontal allocation
  # bars.
  #
  # @return [Array<Hash>] sorted descending by allocation; each element has:
  #   * +:fund_name+  [String]
  #   * +:allocation+ [Float] percentage weight in the portfolio
  #   * +:value+      [Float] invested value in currency
  def calculate_allocation_data
    @portfolio.fund_investments.includes(:investment_fund).map do |fi|
      {
        fund_name: fi.investment_fund.fund_name,
        allocation: fi.percentage_allocation.to_f,
        value: fi.total_invested_value.to_f
      }
    end.sort_by { |a| -a[:allocation] }
  end

  # Groups portfolio allocation percentages by normative article name.
  #
  # When a fund is linked to multiple articles, its allocation is split
  # equally among them. Funds with no articles are assigned to the +'-'+
  # bucket.
  #
  # @return [Hash{String => Float}] article name → cumulative allocation (%)
  def calculate_article_groups
    groups = Hash.new(0.0)
    @portfolio.fund_investments
              .includes(investment_fund: { investment_fund_articles: :normative_article })
              .each do |fi|
      articles = fi.investment_fund.investment_fund_articles
      if articles.any?
        articles.each do |ifa|
          label = ifa.normative_article&.article_name || '-'
          groups[label] += fi.percentage_allocation.to_f / articles.size
        end
      else
        groups['-'] += fi.percentage_allocation.to_f
      end
    end
    groups
  end

  # Groups allocation, market value, and earnings by the benchmark index of
  # each fund investment.
  #
  # Earnings are sourced from the pre-loaded +@performance_data+ to avoid
  # additional queries and to remain consistent with the cover-page figures.
  #
  # @return [Hash{String => Hash}] index abbreviation →
  #   +{ allocation: Float, value: Float, earnings: Float }+
  def calculate_index_groups
    groups = Hash.new { |h, k| h[k] = { allocation: 0.0, value: 0.0, earnings: 0.0 } }

    perf_by_fi = (@performance_data[:performances] || [])
                   .index_by(&:fund_investment_id)

    @portfolio.fund_investments.includes(:investment_fund).each do |fi|
      ref = fi.investment_fund.benchmark_index.presence || '-'
      groups[ref][:allocation] += fi.percentage_allocation.to_f
      groups[ref][:value] += fi.current_market_value_on(@reference_date).to_f
      groups[ref][:earnings] += perf_by_fi[fi.id]&.earnings.to_f
    end

    groups
  end

  # Groups market value and allocation by administrator/institution name.
  #
  # @return [Hash{String => Hash}] institution name →
  #   +{ value: Float, allocation: Float }+
  def calculate_institution_groups
    groups = Hash.new { |h, k| h[k] = { value: 0.0, allocation: 0.0 } }

    @portfolio.fund_investments.includes(:investment_fund).each do |fi|
      inst = fi.investment_fund.administrator_name.presence || 'Outros'
      groups[inst][:value] += fi.current_market_value_on(@reference_date).to_f
      groups[inst][:allocation] += fi.percentage_allocation.to_f
    end

    groups
  end

  # Groups market value and earnings by the normative category of each fund's
  # first article.
  #
  # Funds with no articles default to the +'Fundos ou ETF 100% TPF'+ category
  # so every asset is always classified.
  #
  # Earnings are sourced from the pre-loaded +@performance_data+ records for
  # consistency with the rest of the report.
  #
  # @return [Hash{String => Hash}] category name →
  #   +{ value: Float, earnings: Float }+
  def calculate_asset_type_groups
    groups = Hash.new { |h, k| h[k] = { value: 0.0, earnings: 0.0 } }

    perf_by_fi = (@performance_data[:performances] || [])
                   .index_by(&:fund_investment_id)

    @portfolio.fund_investments
              .includes(:investment_fund, :applications, :redemptions,
                        investment_fund: { investment_fund_articles: :normative_article })
              .each do |fi|

      articles = fi.investment_fund.investment_fund_articles
      label = articles.any? ?
                (articles.first.normative_article&.category.presence || 'Fundos ou ETF 100% TPF') :
                'Fundos ou ETF 100% TPF'
      label = 'Fundos ou ETF 100% TPF' if label == 'Renda Fixa Geral'

      groups[label][:value] += fi.current_market_value_on(@reference_date).to_f
      groups[label][:earnings] += perf_by_fi[fi.id]&.earnings.to_f
    end

    groups
  end

  # Computes compliance status for every normative article linked to funds
  # in the portfolio.
  #
  # Compliance is evaluated as:
  # * +within_range = true+ if +min <= current <= max+ (when limits are set)
  # * +within_range = true+ if +|current - target| <= 5.0%+ (when only target
  #   is set)
  # * +within_range = true+ when neither limits nor target are defined
  #
  # Articles where the portfolio has zero allocation AND no benchmark target
  # are skipped.
  #
  # @return [Hash{String => Hash}] article label → compliance detail hash with:
  #   * +:display_name+  [String]
  #   * +:current+       [Float] current allocation (%)
  #   * +:target+        [Float]
  #   * +:min+           [Float, nil]
  #   * +:max+           [Float, nil]
  #   * +:within_range+  [Boolean]
  def calculate_policy_compliance
    result = {}

    NormativeArticle
      .joins(:investment_fund_articles)
      .includes(investment_fund_articles: { investment_fund: :fund_investments })
      .distinct
      .each do |article|

      current_alloc = 0.0
      article.investment_fund_articles.each do |ifa|
        fi = ifa.investment_fund.fund_investments.find { |f| f.portfolio_id == @portfolio.id }
        current_alloc += fi.percentage_allocation.to_f if fi
      end

      next if current_alloc.zero? && article.benchmark_target.blank?

      label = [article.article_number.presence, article.article_name.presence]
                .compact.join(': ').presence || "Art. ##{article.id}"

      min_v = article.try(:min_allocation)&.to_f
      max_v = article.try(:max_allocation)&.to_f
      tgt_v = article.benchmark_target.to_f

      within = if min_v && max_v
                 current_alloc >= min_v && current_alloc <= max_v
               elsif tgt_v > 0
                 (current_alloc - tgt_v).abs <= 5.0
               else
                 true
               end

      result[label] = {
        display_name: label,
        current: current_alloc.round(2),
        target: tgt_v,
        min: min_v,
        max: max_v,
        within_range: within
      }
    end

    result
  rescue StandardError => e
    Rails.logger.error("Error calculating policy compliance: #{e.message}")
    {}
  end

  # Fetches rolling 12-month history for every +EconomicIndex+ record.
  #
  # Values for each index are grouped by their calendar month so they can be
  # looked up by +beginning_of_month+ Date keys throughout the report.
  #
  # @return [Hash{String => Hash{Date => Float}}]
  #   index abbreviation → { beginning_of_month_date => monthly_value }
  def collect_economic_indices_history
    start_date = (@reference_date - 11.months).beginning_of_month
    result = {}

    EconomicIndex.all.each do |idx|
      rows = idx.economic_index_histories
                .where(date: start_date..@reference_date)
                .order(:date)
                .group_by { |r| r.date.beginning_of_month }

      result[idx.abbreviation] = rows.transform_values { |recs| recs.sum(&:value).to_f }
    end

    result
  end

  # Builds the investment policy data array used by the policy-compliance page.
  #
  # Each entry corresponds to a +NormativeArticle+ that has a non-zero
  # allocation in the portfolio. The +:carteira_atual+ value represents
  # the sum of +percentage_allocation+ across all fund investments linked
  # to that article.
  #
  # Only fund investments with non-zero earnings or a positive initial balance
  # in the current period are considered active and included in the
  # allocation totals.
  #
  # Requires the +minimum_target+ and +maximum_target+ columns on
  # +normative_articles+ (accessed via +try+ for forward-compatibility before
  # the migration is applied):
  #
  #   add_column :normative_articles, :minimum_target, :decimal, precision: 8, scale: 4
  #   add_column :normative_articles, :maximum_target, :decimal, precision: 8, scale: 4
  #
  # @return [Array<Hash>] each element has:
  #   * +:id+              [Integer]
  #   * +:label+           [String]  human-readable article label
  #   * +:article_number+  [String]
  #   * +:carteira_atual+  [Float]   current portfolio allocation (%)
  #   * +:alvo+            [Float]   target allocation (%)
  #   * +:minimo+          [Float]   minimum allocation (%)
  #   * +:maximo+          [Float]   maximum allocation (%)
  #   * +:compliant+       [Boolean]
  def collect_investment_policy_data
    active_fi_ids = (@performance_data[:performances] || [])
                      .select { |p| p.earnings.to_f != 0 || p.initial_balance.to_f > 0 }
                      .map(&:fund_investment_id)
                      .to_set

    perf_by_fi = (@performance_data[:performances] || [])
                   .each_with_object({}) { |p, h| h[p.fund_investment_id] = p }

    total_initial = perf_by_fi.values.sum { |p| p.initial_balance.to_f }

    alloc_by_article = Hash.new(0.0)
    # Coleta também os metadados de cada artigo para usar abaixo
    article_meta = {}

    @portfolio.fund_investments
              .includes(investment_fund: { investment_fund_articles: :normative_article })
              .select { |fi| active_fi_ids.include?(fi.id) }
              .each do |fi|
      perf = perf_by_fi[fi.id]
      next unless perf && perf.initial_balance.to_f > 0

      weight = total_initial > 0 ? (perf.initial_balance.to_f / total_initial * 100) : 0.0
      articles = fi.investment_fund.investment_fund_articles.select(&:normative_article)
      next if articles.empty?

      articles.each do |ifa|
        art = ifa.normative_article
        alloc_by_article[art.id] += weight / articles.size
        article_meta[art.id] ||= art
      end
    end

    # --- MUDANÇA PRINCIPAL ---
    # Base: portfolio_normative_articles existentes
    pna_by_article_id = @portfolio
                          .portfolio_normative_articles
                          .includes(:normative_article)
                          .each_with_object({}) { |pna, h| h[pna.normative_article_id] = pna }

    # União de artigos: os configurados no portfólio + os que vieram dos fundos ativos
    all_article_ids = (pna_by_article_id.keys + alloc_by_article.keys).uniq

    NormativeArticle
      .where(id: all_article_ids)
      .map do |art|
      pna = pna_by_article_id[art.id]

      carteira_atual = alloc_by_article[art.id].to_f.round(4)

      # Se não há PNA cadastrado, usa os valores do próprio artigo como fallback
      alvo   = pna ? pna.benchmark_target.to_f : art.benchmark_target.to_f
      minimo = pna ? pna.minimum_target.to_f   : art.try(:minimum_target).to_f
      maximo = pna ? pna.maximum_target.to_f   : art.try(:maximum_target).to_f

      compliant = if maximo > 0 || minimo > 0
                    carteira_atual >= minimo && (maximo.zero? || carteira_atual <= maximo)
                  else
                    true
                  end

      {
        id:              art.id,
        label:           art.display_name,
        article_number:  art.article_number.presence || art.article_name.presence || "Art. ##{art.id}",
        carteira_atual:  carteira_atual,
        category:        art.category.presence || art.article_name.presence || "Não classificado",
        alvo:            alvo,
        minimo:          minimo,
        maximo:          maximo,
        compliant:       compliant
      }
    end
    .compact
    .sort_by { |r| -r[:carteira_atual] }
  end

  # Retrieves checking account records for the portfolio within the month of
  # +@requested_reference_date+.
  #
  # Uses +@requested_reference_date+ rather than +@reference_date+ to avoid
  # the performance-data fallback silently shifting the accounts lookup to a
  # different period.
  #
  # Tolerant to schema errors (e.g., table not yet migrated) — returns an
  # empty array and logs a warning in those cases.
  #
  # @return [Array<Hash>] each element has:
  #   * +:name+           [String]
  #   * +:institution+    [String]
  #   * +:account_number+ [String] or +'-'+ when absent
  #   * +:balance+        [Float]
  #   * +:notes+          [String] or +'-'+ when absent
  def collect_checking_accounts
    ref = @requested_reference_date
    month_start = ref.beginning_of_month
    month_end = ref.end_of_month

    ::CheckingAccount
      .where(portfolio: @portfolio, reference_date: month_start..month_end)
      .order(:institution, :name)
      .map do |ca|
      {
        name: ca.name,
        institution: ca.institution,
        account_number: ca.account_number.presence || '-',
        balance: ca.balance.to_f,
        notes: ca.notes.presence || '-'
      }
    end
  rescue StandardError => e
    Rails.logger.warn("[PortfolioMonthlyReportGenerator] collect_checking_accounts: #{e.message}")
    Rails.logger.debug(e.backtrace.first(3).join("\n"))
    []
  end

  # ---------------------------------------------------------------------------
  # Global page decorations
  # ---------------------------------------------------------------------------

  # Stamps a two-line footer on every page using Prawn's +repeat(:all)+
  # callback.
  #
  # Line 1 displays the company name; Line 2 displays contact details on the
  # left and the page number ("+n+ de +total+") on the right.
  #
  # @return [void]
  def stamp_global_footer
    total = pdf.page_count

    pdf.repeat(:all, dynamic: true) do
      footer_y = -MARGIN_B + 18

      # 1. Nome da Empresa (Centralizado)
      pdf.font('Plus Jakarta Sans', size: 6) do
        pdf.fill_color C[:muted]
        company_w = pdf.width_of(COMPANY)
        pdf.draw_text COMPANY, at: [(CONTENT_W - company_w) / 2.0, footer_y + 16]
      end

      # 2. Contatos e Paginação
      pdf.font('Geist Pixel Square', size: 6) do
        pdf.fill_color C[:gray_light]

        # Dados de Contato (Centralizado)
        contact_text = "#{PHONE}  ·  #{EMAIL}  ·  #{SITE}  ·  #{CNPJ}"
        contact_w = pdf.width_of(contact_text)
        pdf.draw_text contact_text, at: [(CONTENT_W - contact_w) / 2.0, footer_y + 6]

        # Paginação (Centralizado, abaixo dos contatos)
        page_text = "#{pdf.page_number} de #{total}"
        page_w = pdf.width_of(page_text)
        pdf.draw_text page_text, at: [(CONTENT_W - page_w) / 2.0, footer_y - 8]
      end
    end
  end

  # Applies the company logo as a semi-transparent rotated watermark on every
  # page except the cover (page 1).
  #
  # The method iterates over already-created pages and renders the watermark
  # retroactively, then registers an +on_page_create+ callback to ensure
  # future pages also receive it.
  #
  # Silently skips if the watermark image file does not exist.
  #
  # @return [void]
  def stamp_watermark
    return unless File.exist?(WATERMARK_IMAGE_PATH)

    wm_w = WATERMARK_WIDTH.to_f
    img_x = (CONTENT_W - wm_w) / 2.0
    img_y = (PAGE_H - MARGIN_T - MARGIN_B) / 2.0 + (wm_w / 2.0)

    draw_wm = lambda do
      next if pdf.page_number == 1

      pdf.save_graphics_state do
        pdf.image WATERMARK_IMAGE_PATH.to_s, at: [img_x, img_y], width: wm_w
      end
    end

    (2..pdf.page_count).each do |page_num|
      pdf.go_to_page(page_num)
      pdf.transparent(0.03) do
        pdf.image WATERMARK_IMAGE_PATH.to_s, at: [img_x, img_y], width: wm_w
      end
    end

    pdf.on_page_create { draw_wm.call }
  rescue StandardError => e
    Rails.logger.warn("[PortfolioMonthlyReportGenerator] stamp_watermark: #{e.message}")
  end

  # ---------------------------------------------------------------------------
  # Page renderers
  # ---------------------------------------------------------------------------

  # Renders five key-metric cards in a horizontal row at the top of the
  # summary page.
  #
  # Each card has a light-tinted background, a small label in Plus Jakarta Sans,
  # and a large value in Geist Pixel Square, matching the visual language of
  # the cover page but laid out as a 5-column grid.
  #
  # @return [void]
  def draw_summary_metrics_horizontal
    perf = data[:performance]

    metrics = [
      { label: 'Rent. do Mês', value: fmt_pct(perf[:monthly_return]) },
      { label: 'Rent. do Ano', value: fmt_pct(perf[:yearly_return]) },
      { label: 'Ganhos do Mês', value: fmt_cur(perf[:total_earnings]) },
      { label: 'Ganhos Acum. do Ano', value: fmt_cur(perf[:yearly_earnings]) },
      { label: 'Total da Carteira', value: fmt_cur(perf[:total_value]) }
    ]

    card_gap = 6
    card_w = (CONTENT_W - card_gap * (metrics.size - 1)) / metrics.size.to_f
    card_h = 52
    card_radius = 2
    top_y = pdf.cursor

    metrics.each_with_index do |m, i|
      x = i * (card_w + card_gap)

      pdf.fill_color C[:bg_light]
      pdf.fill_rounded_rectangle [x, top_y], card_w, card_h, card_radius

      pdf.fill_color C[:muted]
      pdf.font('Plus Jakarta Sans', size: 7) do
        pdf.text_box m[:label],
                     at: [x + 8, top_y - 8],
                     width: card_w - 16,
                     height: 12,
                     overflow: :shrink_to_fit,
                     align: :left
      end

      pdf.fill_color C[:body]
      pdf.font('Geist Pixel Square', size: 11) do
        pdf.text_box m[:value],
                     at: [x + 8, top_y - 24],
                     width: card_w - 16,
                     height: 18,
                     overflow: :shrink_to_fit,
                     align: :left
      end
    end

    pdf.move_down card_h + 16
  rescue StandardError => e
    Rails.logger.error("[draw_summary_metrics_horizontal] #{e.message}")
    pdf.move_down 20
  end

  # Renders a two-column section titled with portfolio performance relative
  # to the target (META) and relative to market indices.
  #
  # Left column  — semi-circular gauge showing the percentage of META achieved.
  # Right column — horizontal index-comparison bars (CDI, IPCA, IMA).
  #
  # Both sub-elements use absolute coordinates so their X origins are
  # offset explicitly: the gauge is centred within the left half, and the
  # bar chart is shifted right by +left_w + col_gap+.
  #
  # @param meta_r_gauge [Float]  percentage of META achieved (e.g. 164.02)
  # @param cdi_pct      [Float]  portfolio return as % of CDI YTD
  # @param ipca_pct     [Float]  portfolio return as % of IPCA YTD
  # @param ima_pct      [Float]  portfolio return as % of IMA-Geral YTD
  # @return [void]
  def draw_summary_meta_vs_indices(meta_r_gauge:, cdi_pct:, ipca_pct:, ima_pct:)
    col_gap = 40
    left_w = CONTENT_W * 0.42
    right_w = CONTENT_W - left_w - col_gap
    right_x = left_w + col_gap
    title_h = 40

    draw_section(title: nil, info: nil, border: false, spacing: 10) do
      section_top = pdf.cursor

      pdf.fill_color C[:body]
      pdf.font('Geist Mono', size: 14) do
        pdf.text_box 'RENTABILIDADE EM RELAÇÃO À META',
                     at: [0, section_top],
                     width: left_w * 0.75,
                     height: title_h,
                     align: :left,
                     overflow: :shrink_to_fit
      end

      border_y = section_top - title_h
      pdf.stroke_color C[:border]
      pdf.stroke_horizontal_line 0, left_w, at: border_y - 3
      pdf.move_down 10

      pdf.fill_color C[:body]
      pdf.font('Geist Mono', size: 14) do
        pdf.text_box 'CARTEIRA EM RELAÇÃO AOS ÍNDICES',
                     at: [right_x, section_top],
                     width: right_w * 0.75,
                     height: title_h,
                     align: :left,
                     overflow: :shrink_to_fit
      end

      pdf.stroke_color C[:border]
      pdf.stroke_horizontal_line right_x, CONTENT_W, at: border_y - 3
      pdf.move_down 10

      gauge_radius = 65
      gauge_cx = left_w / 2.0
      gauge_cy = section_top - title_h - gauge_radius - 18
      draw_gauge_meter(value: meta_r_gauge, max: 200.0, cx: gauge_cx, cy: gauge_cy, radius: gauge_radius)

      rel_items = [
        { label: 'Do CDI%', value: cdi_pct, color: C[:secondary] },
        { label: 'Do IPCA%', value: ipca_pct, color: C[:secondary] },
        { label: 'Do IMA%', value: ima_pct, color: C[:secondary] }
      ]

      bar_max = rel_items.map { |r| r[:value].to_f }.max.nonzero? || 1.0
      bar_area = right_w - 70
      bar_h = 14
      gap = 26
      rel_top = section_top - title_h - 30

      rel_items.each_with_index do |item, idx|
        by = rel_top - idx * gap
        bar_w = (item[:value].to_f / bar_max * bar_area).round(1)

        pdf.fill_color C[:muted]
        pdf.font('Geist Pixel Square', size: 7) do
          pdf.draw_text item[:label], at: [right_x, by + 4]
        end

        pdf.fill_color item[:color]
        pdf.fill_rounded_rectangle [right_x + 55, by + bar_h - 2], [bar_w, 1].max, bar_h - 2, 2

        pdf.fill_color C[:muted]
        pdf.font('Geist Pixel Square', size: 8) do
          pdf.draw_text "#{fmt_num(item[:value], 2)}%", at: [right_x + 55 + bar_w + 5, by + 4]
        end
      end

      pdf.move_down [title_h + gauge_radius + 40, title_h + rel_items.size * gap + 30].max
    end
  rescue StandardError => e
    Rails.logger.error("[draw_summary_meta_vs_indices] #{e.message}")
    pdf.move_down 20
  end

  # Renders the portfolio performance summary page.
  #
  # Contains:
  # * Five metric cards (monthly return, YTD return, monthly earnings,
  #   YTD earnings, total portfolio value)
  # * Semi-circular gauge showing percentage of META achieved
  # * Horizontal bar chart comparing portfolio return vs CDI/IPCA/IMA
  # * Grouped bar chart — portfolio vs META month-by-month
  # * Monthly earnings bar chart
  #
  # @return [void]
  def render_summary_page
    draw_page(title: @portfolio.name, first_page: true) do
      perf = data[:performance]
      bnch = data[:benchmarks]

      cdi_pct = bnch[:cdi][:ytd].to_f > 0 ? (perf[:yearly_return].to_f / bnch[:cdi][:ytd].to_f * 100).round(2) : 0
      ipca_pct = bnch[:ipca][:ytd].to_f > 0 ? (perf[:yearly_return].to_f / bnch[:ipca][:ytd].to_f * 100).round(2) : 0
      ima_pct = bnch[:ima_geral][:ytd].to_f > 0 ? (perf[:yearly_return].to_f / bnch[:ima_geral][:ytd].to_f * 100).round(2) : 0

      monthly_returns = build_yearly_returns_series
      meta_series = build_yearly_meta_series

      draw_summary_metrics_horizontal

      pdf.move_down 20

      meta_r_gauge = bnch[:meta][:ytd].to_f > 0 ? (perf[:yearly_return].to_f / bnch[:meta][:ytd].to_f * 100).round(2) : 0.0
      draw_summary_meta_vs_indices(meta_r_gauge: meta_r_gauge, cdi_pct: cdi_pct, ipca_pct: ipca_pct, ima_pct: ima_pct)

      pdf.move_down 20

      draw_section(title: 'Desempenho da Carteira', info: 'Mês a Mês', border: true, spacing: 25) do
        bar_data = monthly_returns.zip(meta_series).map do |cart, meta|
          [cart[:label], cart[:value].to_f, meta[:value].to_f]
        end

        yearly_twr = perf[:yearly_return].to_f
        meta_ytd = data[:benchmarks][:meta][:ytd].to_f
        bar_data << ['Total', yearly_twr, meta_ytd]

        draw_grouped_bar_chart(
          data: bar_data,
          labels: ['Carteira', 'Meta'],
          colors: [C[:primary], C[:warning]],
          height: 100, y: pdf.cursor,
          skip_auto_total: true
        )
        pdf.move_down 115
      end

      pdf.move_down 20

      draw_section(title: 'Rendimento Mensal', info: 'Mês a Mês', border: true, spacing: 25) do
        draw_earnings_waterfall(
          data: build_yearly_earnings_series,
          height: 90, y: pdf.cursor
        )
        pdf.move_down 105
      end
    end
  end

  # Renders the fund-details page.
  #
  # Contains:
  # * Per-fund table: earnings, net movements, ending balance, and monthly
  #   return percentage
  # * Checking accounts table with balance and percentage of the total
  # * A separate sub-page listing each fund's CNPJ, normative article,
  #   reference index, and administration fee
  #
  # Only funds with non-zero activity in the reference month (earnings,
  # applications, or redemptions) are included in the tables.
  #
  # @return [void]
  def render_fund_details_page
    draw_page(title: @portfolio.name) do
      perf_by_fi = (@performance_data[:performances] || []).index_by(&:fund_investment_id)

      fund_rows = [['Fundo', 'Rendimento', 'Movimentação', 'Valor Final', 'Rent.']]

      total_earn = 0.0
      total_move = 0.0
      total_final = 0.0

      data[:fund_investments].select do |fi|
        perf = perf_by_fi[fi.id]
        earn = perf&.earnings.to_f
        apps = monthly_apps_for(fi)
        reds = monthly_reds_for(fi)
        earn != 0 || apps != 0 || reds != 0
      end.sort_by { |fi| fi.investment_fund.fund_name }.each do |fi|  # ← aqui
        perf = perf_by_fi[fi.id]
        init = perf&.initial_balance.to_f
        earn = perf&.earnings.to_f
        apps = monthly_apps_for(fi)
        reds = monthly_reds_for(fi)
        move = apps - reds
        final = init + earn + move
        rent = perf&.monthly_return.to_f
        total_earn += earn
        total_move += move
        total_final += final
        fund_rows << [
          fi.investment_fund.fund_name,
          fmt_cur(earn), fmt_cur(move), fmt_cur(final), fmt_pct(rent)
        ]
      end

      fund_rows << ['Total', fmt_cur(total_earn), fmt_cur(total_move), fmt_cur(total_final), '']

      draw_section(title: 'Carteira de Investimentos', info: month_year_label, border: true, spacing: 20) do
        styled_table(fund_rows, col_widths: [265, 65, 65, 90, 30], last_row_bold: false)
      end

      pdf.move_down 40

      accounts = data[:checking_accounts]
      total_balance = accounts.sum { |a| a[:balance] }

      draw_section(title: 'Relação de Contas Correntes', info: month_year_label, border: true, spacing: 0) do
        rows = [['Instituição', 'Nº da Conta', 'Saldo', '% do Total']]

        accounts.sort_by { |a| -a[:balance] }.each do |a|
          pct = total_balance > 0 ? (a[:balance] / total_balance * 100).round(2) : 0
          rows << [
            truncate(a[:institution], 30),
            a[:account_number], fmt_cur(a[:balance]), fmt_pct(pct)
          ]
        end

        rows << ['Total das Disponibilidades', '', fmt_cur(total_balance), '100,00%']

        col_widths = [180, 110, 120, 105]

        pdf.table(
          rows.map { |r| r.map { |c| c.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?') } },
          header: true, width: CONTENT_W, column_widths: col_widths,
          cell_style: {
            font: 'Plus Jakarta Sans', size: 8, padding: [5, 7],
            borders: %i[top bottom], border_color: C[:border],
            border_width: 1, text_color: C[:body]
          }
        ) do |t|
          t.row(0).tap { |r| r.text_color = C[:white]; r.background_color = C[:primary] }
          (1...rows.size - 1).each { |ri| t.row(ri).background_color = C[:white] }

          last = rows.size - 1
          t.row(last).background_color = C[:bg_light]
          t.row(last).borders = %i[top bottom]
          t.row(last).border_color = C[:body]
          t.cells[last, 2].font = 'Geist Pixel Square'
          t.cells[last, 2].size = 9
          t.cells[last, 2].text_color = C[:primary]
        end
      rescue Prawn::Errors::CannotFit
        styled_table(rows)
      end

      pdf.start_new_page

      draw_section(title: 'Relação dos Fundos e Ativos', border: true, spacing: 20) do
        rel_rows = [['CNPJ do Fundo', 'Nome do Fundo', 'Enq. 5.272/25', 'Taxa Adm.']]

        data[:fund_investments].select do |fi|
          perf = perf_by_fi[fi.id]
          earn = perf&.earnings.to_f
          apps = monthly_apps_for(fi)
          reds = monthly_reds_for(fi)
          earn != 0 || apps != 0 || reds != 0
        end.each do |fi|
          fund = fi.investment_fund
          enq = fund.investment_fund_articles.first&.normative_article&.article_number || '-'
          adm = fund.administration_fee.present? ? "#{fmt_num(fund.administration_fee.to_f, 2)}%" : '-'

          rel_rows << [
            fund.cnpj.presence || '-', fund.fund_name, enq, adm
          ]
        end

        styled_table(rel_rows, col_widths: [100, 220, 80, 45])
      end
    end
  end

  # Renders the monthly patrimonial history page (two Prawn pages).
  #
  # Page 1 contains:
  # * Bar chart — total patrimony by month
  # * Patrimony table (Jan–Dec of the reference year)
  #
  # Page 2 contains:
  # * Waterfall chart — net cash flows by month
  # * Flows table (Jan–Dec of the reference year)
  #
  # Closing balances for past months are derived from the +initial_balance+
  # of the following month's +PerformanceHistory+ records. The current month
  # uses the live mark-to-market value plus checking-account balances.
  #
  # @return [void]
  def render_monthly_history_page
    accounts = data[:checking_accounts]
    accounts_total = accounts.sum { |a| a[:balance] }
    ref_month = @reference_date.beginning_of_month
    perf = data[:performance]

    closing_balance_by_month = begin
                                 periods_needed = data[:monthly_history].map { |m| m[:period] }
                                 next_periods = periods_needed.map { |p| p.next_month.end_of_month }

                                 @portfolio.performance_histories
                                           .where(period: (periods_needed + next_periods).uniq)
                                           .group(:period)
                                           .sum(:initial_balance)
                               end

    total_patrimony = ->(m) {
      if m[:period].beginning_of_month == ref_month
        perf[:total_value] + accounts_total
      else
        next_period = m[:period].next_month.end_of_month
        closing = closing_balance_by_month[next_period].to_f
        period_accounts = CheckingAccount
                            .where(portfolio: @portfolio,
                                   reference_date: m[:period].beginning_of_month..m[:period].end_of_month)
                            .sum(:balance).to_f
        closing + period_accounts
      end
    }

    draw_page(title: @portfolio.name) do
      hist = data[:monthly_history]

      draw_section(title: 'Patrimônio Total por Mês', info: 'Gráfico', border: true, spacing: 25) do
        draw_bar_chart(
          data: build_yearly_patrimony_series(total_patrimony: total_patrimony),
          height: 140, y: pdf.cursor, color: C[:primary],
          show_total: false
        )
      end

      pdf.move_down 180

      draw_section(title: 'Patrimônio Total por Mês', info: 'Tabela', border: true, spacing: 24) do
        hist_by_month = hist.each_with_object({}) { |m, h| h[m[:period].beginning_of_month] = m }

        pat_rows = [['Mês', 'Patrimônio Total', 'Rendimento Mensal']]
        (1..12).each do |month|
          period = Date.new(@reference_date.year, month, 1)
          m = hist_by_month[period]
          pat_rows << [
            full_month(period),
            m ? fmt_cur(total_patrimony.(m)) : fmt_cur(0),
            m ? fmt_cur(m[:earnings]) : fmt_cur(0)
          ]
        end

        styled_table(pat_rows, col_widths: [200, 160, 155])
      end
    end

    draw_page do
      year = @reference_date.year

      yearly_flows = (1..12).map do |month|
        period = Date.new(year, month, 1)
        data[:monthly_flows].find { |f| f[:period].beginning_of_month == period } ||
          { period: period, applications: 0.0, redemptions: 0.0 }
      end

      draw_section(title: 'Movimentações por Mês', info: 'Gráfico', border: true, spacing: 0) do
        draw_waterfall_chart(flows: yearly_flows, height: 90, y: pdf.cursor)
      end

      pdf.move_down 150

      draw_section(title: 'Movimentações por Mês', info: 'Tabela', border: true, spacing: 0) do
        flows_by_month = yearly_flows.each_with_object({}) { |f, h| h[f[:period].beginning_of_month] = f }

        flow_rows = [['Mês', 'Aplicações', 'Resgates', 'Movimentação Líquida']]
        (1..12).each do |month|
          period = Date.new(year, month, 1)
          f = flows_by_month[period]
          apps = f ? f[:applications] : 0.0
          reds = f ? f[:redemptions] : 0.0
          flow_rows << [
            full_month(period),
            fmt_cur(apps),
            fmt_cur(reds),
            fmt_cur(apps - reds)
          ]
        end

        styled_table(flow_rows, col_widths: [160, 115, 115, 125])
      end
    end
  end

  # Renders the fund distribution page.
  #
  # Contains:
  # * Allocation horizontal bars per fund
  # * Donut chart by reference index
  # * Donut chart by financial institution (on a separate sub-page)
  # * Donut chart by normative category (on the same sub-page)
  # * Patrimony by reference index table
  #
  # @return [void]
  def render_fund_distribution_page
    draw_page(title: @portfolio.name) do
      alloc = data[:allocation]
      return if alloc.empty?

      draw_section(title: 'Distribuição da carteira por Fundos', info: month_year_label, border: true, spacing: 0) do
        draw_allocation_bars(alloc, y: pdf.cursor)
      end

      pdf.move_down 40

      draw_section(title: 'Distribuição por índices de referência', info: "Gráfico", border: true, spacing: 0) do
        idx_groups = data[:index_groups]
        donut_data = idx_groups.map { |k, v| { label: k, value: v[:allocation] } }.sort_by { |d| -d[:value] }

        draw_donut_chart(data: donut_data, cx: 120, cy: pdf.cursor - 80, radius: 70,
                         legend_x: 210, legend_y: pdf.cursor - 30)
        pdf.move_down 160
      end

      pdf.start_new_page

      idx_groups = data[:index_groups]
      return if idx_groups.empty?

      draw_section(title: 'Patrimônio por Índice de Referência', info: "Tabela", border: true, spacing: 0) do
        total_value_idx = idx_groups.values.sum { |v| v[:value] }

        rows = [['Índice de Referência', 'Patrimônio do Mês', '% do Total']]
        idx_groups.sort_by { |_, v| -v[:value] }.each do |k, v|
          pct = total_value_idx > 0 ? (v[:value] / total_value_idx * 100).round(2) : 0
          rows << [k, fmt_cur(v[:value]), fmt_pct(pct)]
        end
        rows << ['Total', fmt_cur(total_value_idx), '100,00%']
        styled_table(rows, col_widths: [200, 190, 125], last_row_bold: false)

        pdf.move_down 20
      end

      pdf.start_new_page

      inst_groups = data[:institution_groups]

      unless inst_groups.empty?
        draw_section(title: 'Distribuição por Instituição Financeira', border: true, spacing: 0) do
          inst_data = inst_groups
                        .map { |k, v| { label: k, value: v[:value] } }
                        .sort_by { |d| -d[:value] }

          draw_donut_chart(
            data: inst_data,
            cx: 130,
            cy: pdf.cursor - 90,
            radius: 80,
            hole_ratio: 0.6,
            legend_x: 225,
            legend_y: pdf.cursor - 40
          )

          pdf.move_down 185
        end
      end
      pdf.move_down 40

      draw_section(title: 'Distribuição por Categoria Normativa', border: true, spacing: 10) do
        category_groups = Hash.new(0.0)

        data[:portfolio_normative].each do |r|
          cat = r[:display_name].presence || 'Não Classificado'
          category_groups[cat] += r[:carteira_atual].to_f
        end

        cat_data = category_groups.map { |k, v| { label: k, value: v } }
                                  .reject { |d| d[:value] <= 0 }
                                  .sort_by { |d| -d[:value] }

        category_colors = {
          'Renda Fixa'            => C[:primary],
          'Renda Variável'        => C[:secondary],
          'Investimento Exterior' => C[:warning],
          'Não Classificado'      => C[:muted]
        }
        cat_data.each { |d| d[:color] = category_colors[d[:label]] }

        draw_donut_chart(data: cat_data, cx: 130, cy: pdf.cursor - 90, radius: 80,
                         legend_x: 225, legend_y: pdf.cursor - 40)
      end    end

    compliance = data[:policy_compliance]
    return if compliance.empty?
  end

  # Renders earnings and patrimony broken down by benchmark reference index
  # as horizontal bar charts on a single Prawn page.
  #
  # @return [void]
  def render_index_earnings_page
    draw_page(title: @portfolio.name) do
      idx_groups = data[:index_groups]

      draw_section(title: 'Rendimento por Índice de Referência', info: month_year_label, border: true, spacing: 0) do
        earn_data = idx_groups.map { |k, v| { label: k, value: v[:earnings] } }.sort_by { |d| -d[:value] }
        draw_horizontal_bars(data: earn_data, color: C[:secondary], y: pdf.cursor)
      end

      pdf.move_down 40

      draw_section(title: 'Patrimônio por Índice de Referência do Mês', border: true, spacing: 0) do
        pat_data = idx_groups.map { |k, v| { label: k, value: v[:value] } }.sort_by { |d| -d[:value] }
        draw_horizontal_bars(data: pat_data, color: C[:primary], y: pdf.cursor)
      end
    end
  end

  # Renders a dedicated page for patrimony broken down by reference index,
  # including a horizontal bars chart, a summary table, and a compliance
  # legend.
  #
  # Returns early if +index_groups+ data is empty.
  #
  # @return [void]
  def render_index_patrimony_page
  end

  # Renders patrimony and earnings broken down by normative asset type category
  # as horizontal bar charts on a single Prawn page.
  #
  # Uses +category_colors+ to map each normative category to a distinct colour
  # that is also shown in a dynamic legend below each chart.
  #
  # Returns early if +asset_type_groups+ is empty.
  #
  # @return [void]
  def render_asset_type_page
    asset_groups = data[:asset_type_groups]
    return if asset_groups.empty?

    category_colors = {
      'Fundos ou ETF 100% TPF' => '1a237e',
      '100% Títulos Públicos' => '1976d2',
      'Investimento Exterior' => '42a5f5',
      'Renda Fixa' => '607d8b'
    }

    draw_page(title: @portfolio.name) do
      draw_section(title: 'Patrimônio por Tipo de Ativo do Mês', info: month_year_label, border: true, spacing: 0) do
        draw_asset_type_bars(asset_groups: asset_groups, value_key: :value,
                             format: :currency, category_colors: category_colors)
      end

      pdf.move_down 4
      draw_dynamic_enquadramento_legend(asset_groups.keys, category_colors)
      pdf.move_down 16

      draw_section(title: 'Rendimento por Tipo de Ativo do Mês', info: month_year_label, border: true, spacing: 0) do
        draw_asset_type_bars(asset_groups: asset_groups, value_key: :earnings,
                             format: :currency, category_colors: category_colors)
      end

      pdf.move_down 4
      draw_dynamic_enquadramento_legend(asset_groups.keys, category_colors)
    end

    pdf.move_down 40
  end

  # Renders the 12-month historical table page.
  #
  # Contains:
  # * Monthly patrimony table (Jan–Dec of the reference year)
  # * Monthly benchmark index table (META, IPCA, CDI, IMA-GERAL, Ibovespa)
  #
  # Months with no portfolio activity display dashes in the index table.
  # Closing balances follow the same logic as {#render_monthly_history_page}.
  #
  # @return [void]
  def render_historical_table_page
    draw_page(title: @portfolio.name) do
      accounts = data[:checking_accounts]
      accounts_total = accounts.sum { |a| a[:balance] }
      ref_month = @reference_date.beginning_of_month
      perf = data[:performance]
      hist = data[:monthly_history]
      year = @reference_date.year

      hist_by_month = hist.each_with_object({}) { |m, h| h[m[:period].beginning_of_month] = m }

      closing_balance_by_month = begin
                                   periods_needed = hist.map { |m| m[:period] }
                                   next_periods = periods_needed.map { |p| p.next_month.end_of_month }

                                   @portfolio.performance_histories
                                             .where(period: (periods_needed + next_periods).uniq)
                                             .group(:period)
                                             .sum(:initial_balance)
                                 end

      yearly_periods = (1..12).map { |month| Date.new(year, month, 1) }

      hist_rows = [['Mês', 'Patrimônio Total', 'Rendimento Mensal']]

      yearly_periods.each do |period|
        m = hist_by_month[period]

        if m
          balance = if period == ref_month
                      perf[:total_value] + accounts_total
                    else
                      next_period = period.next_month.end_of_month
                      closing = closing_balance_by_month[next_period].to_f
                      period_accounts = CheckingAccount
                                          .where(portfolio: @portfolio,
                                                 reference_date: period..period.end_of_month)
                                          .sum(:balance).to_f
                      closing + period_accounts
                    end
          hist_rows << [full_month(period), fmt_cur(balance), fmt_cur(m[:earnings])]
        else
          hist_rows << [full_month(period), fmt_cur(0), fmt_cur(0)]
        end
      end

      total_earnings = yearly_periods.sum { |p| hist_by_month[p]&.dig(:earnings) || 0.0 }
      hist_rows << ['Total', '', fmt_cur(total_earnings)]

      draw_section(title: 'Histórico Mensal', border: true, spacing: 22) do
        styled_table(hist_rows, col_widths: [200, 157, 158], last_row_bold: false)
      end

      pdf.move_down 20

      eco = data[:economic_indices]
      bnch = data[:benchmarks]

      active_months = hist
                        .reject { |m| m[:balance] == 0.0 && m[:earnings] == 0.0 }
                        .map { |m| m[:period].beginning_of_month }
                        .to_set

      idx_tbl = [['Mês', 'Meta', 'IPCA', 'CDI', 'IMA-GERAL', 'Ibovespa']]

      yearly_periods.each do |period|
        if active_months.include?(period)
          idx_tbl << [
            full_month(period),
            fmt_pct(meta_monthly_series[period][:meta]),
            fmt_pct(eco['IPCA']&.dig(period) || bnch[:ipca][:monthly]),
            fmt_pct(eco['CDI']&.dig(period) || bnch[:cdi][:monthly]),
            fmt_pct(eco['IMAGERAL']&.dig(period) || bnch[:ima_geral][:monthly]),
            fmt_pct(eco['IBOVESPA']&.dig(period) || bnch[:ibovespa][:monthly])
          ]
        else
          idx_tbl << [full_month(period), '-', '-', '-', '-', '-']
        end
      end

      draw_section(title: 'Índices por Mês', border: true, spacing: 0) do
        styled_table(idx_tbl, col_widths: [140, 75, 75, 75, 85, 65])
      end
    end
  end

  # Renders the investment policy compliance page.
  #
  # Page 1 (rendered when +investment_policy+ data is present): four stacked
  # groups of horizontal bars — one per policy article — for Carteira Atual,
  # Alvo, Máximo, and Mínimo.
  #
  # Page 2 (rendered when +portfolio_normative+ data is present): a styled
  # comparison table showing article targets vs portfolio targets side by side.
  #
  # Returns early if both data sources are empty.
  #
  # @return [void]
  def render_investment_policy_page
    policy = data[:investment_policy]
    pna_data = data[:portfolio_normative]

    return if (policy.nil? || policy.empty?) && pna_data.empty?

    unless policy.nil? || policy.empty?
      article_colors = { 'Art. 7º, Inciso I "b"' => '4faaa0', 'Art. 7º, Inciso III "a"' => '609ed2' }
      default_colors = C[:chart]

      draw_page(title: @portfolio.name) do
        draw_section(title: 'Carteira em relação a política de investimentos', border: true, spacing: 0) do
          [
            { title: 'Carteira Atual por Artigo', key: :carteira_atual },
            { title: 'Alvo Carteira por Artigo', key: :alvo },
            { title: 'Máximo por Artigo', key: :maximo },
            { title: 'Mínimo por Artigo', key: :minimo }
          ].each do |grp|
            # Para grupos que não são carteira_atual, filtra apenas artigos
            # que têm valor configurado (alvo/máximo/mínimo > 0)
            articles_for_group = if grp[:key] == :carteira_atual
                                   policy
                                 else
                                   policy.select { |a| a[grp[:key]].to_f > 0 }
                                 end

            next if articles_for_group.empty?

            pdf.fill_color C[:body]
            pdf.font('Geist Pixel Square', size: 8) do
              pdf.text_box grp[:title], at: [0, pdf.cursor], width: CONTENT_W, align: :center
            end
            pdf.move_down 16

            max_pct = [articles_for_group.map { |a| a[grp[:key]].to_f }.max, 1.0].max
            label_w = 130
            bar_area = CONTENT_W - label_w - 60
            bar_h = 14
            gap = 20

            articles_for_group.each_with_index do |art, idx|
              val = art[grp[:key]].to_f
              bar_w = [(val / max_pct * bar_area).round(1), val > 0 ? 1.0 : 0].max
              color = article_colors[art[:article_number]] || default_colors[idx % default_colors.size]
              by = pdf.cursor - (idx * gap) - bar_h

              pdf.fill_color C[:muted]
              pdf.font('Geist Pixel Square', size: 6.5) { pdf.draw_text truncate(art[:article_number], 24), at: [0, by + 6] }

              pdf.fill_color color
              pdf.fill_rounded_rectangle [label_w, by + bar_h], [bar_w, 0.5].max, bar_h - 2, 2

              pdf.fill_color C[:muted]
              # MUDANÇA: 4 casas decimais
              pdf.font('Geist Pixel Square', size: 6.5) { pdf.draw_text "#{fmt_num(val, 4)}%", at: [label_w + bar_w + 4, by + 6] }
            end

            pdf.move_down articles_for_group.size * gap + 8
            draw_policy_legend(articles_for_group, article_colors, default_colors)
            pdf.move_down 16
          end
        end
        pdf.move_down 20
      end
    end

    return if pna_data.empty?
    draw_page(title: @portfolio.name) do
      draw_section(title: 'Verificação de conformidade da carteira',
                   info: month_year_label,
                   border: true,
                   spacing: 20) do

        header = [
          'Política de Investimentos',
          'Carteira Atual',
          'Alvo',
          'Máximo',
          'Mínimo',
          'Em conformidade'
        ]

        body = pna_data.map do |r|
          compliant = if r[:portfolio_minimum] && r[:portfolio_maximum] && r[:portfolio_maximum] > 0
                        r[:carteira_atual] >= r[:portfolio_minimum] && r[:carteira_atual] <= r[:portfolio_maximum]
                      elsif r[:portfolio_minimum]
                        r[:carteira_atual] >= r[:portfolio_minimum]
                      elsif r[:portfolio_maximum]
                        r[:carteira_atual] <= r[:portfolio_maximum]
                      else
                        true
                      end
          [
            r[:display_name],
            r[:carteira_atual]      ? "#{fmt_num(r[:carteira_atual],      2)}%" : '—',  # ← alocação real
            r[:portfolio_benchmark] ? "#{fmt_num(r[:portfolio_benchmark], 2)}%" : '—',  # ← alvo
            r[:portfolio_maximum]   ? "#{fmt_num(r[:portfolio_maximum],   2)}%" : '—',  # ← máximo do portfólio
            r[:portfolio_minimum]   ? "#{fmt_num(r[:portfolio_minimum],   2)}%" : '—',  # ← mínimo do portfólio
            compliant ? 'Sim' : 'Não'
          ]
        end

        rows = [header] + body
        sanitized = rows.map do |row|
          row.map { |c| c.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?') }
        end

        col_widths = [200, 75, 75, 75, 75, 75]

        pdf.table(sanitized,
                  header: true,
                  width: CONTENT_W,
                  column_widths: col_widths) do |t|

          # Cabeçalho
          t.row(0).tap do |r|
            r.background_color = C[:primary]
            r.text_color = C[:white]
            r.font = 'Plus Jakarta Sans'
            r.size = 7
            r.padding = [6, 8]
            r.borders = %i[top bottom]
            r.border_color = C[:border]
          end

          # Corpo
          (1...sanitized.size).each do |ri|
            t.row(ri).tap do |r|
              r.background_color = C[:white]
              r.font = 'Plus Jakarta Sans'
              r.size = 7
              r.padding = [6, 8]
              r.borders = %i[top bottom]
              r.border_color = C[:border]
              r.text_color = C[:body]
            end

            # Coluna "Em conformidade" colorida
            status_cell = t.cells[ri, 5]
            status_cell.font = 'Geist Pixel Square'
            status_cell.size = 7
            is_sim = sanitized[ri][5] == 'Sim'
            status_cell.text_color = is_sim ? C[:success] : C[:danger]
            status_cell.background_color = C[:white]
          end
        end

      rescue Prawn::Errors::CannotFit
        styled_table(rows)
      end
    end
  end

  # Renders the YTD accumulated indices page.
  #
  # Contains:
  # * Labeled horizontal comparison bars showing each index's accumulated
  #   return alongside its percentage relative to the META target
  # * A summary table (Carteira, META, CDI, IPCA, IMA-GERAL, Ibovespa)
  #
  # @return [void]
  def render_accumulated_indices_page
    draw_page(title: @portfolio.name) do
      perf = data[:performance]
      bnch = data[:benchmarks]

      meta_ytd = bnch[:meta][:ytd].to_f
      cart_ytd = perf[:yearly_return].to_f
      cdi_ytd = bnch[:cdi][:ytd].to_f
      ipca_ytd = bnch[:ipca][:ytd].to_f
      ima_ytd = bnch[:ima_geral][:ytd].to_f
      ibov_ytd = bnch[:ibovespa][:ytd].to_f

      safe_div = ->(num, den) { den > 0 ? (num / den * 100).round(2) : 0 }
      meta_r = safe_div.call(cart_ytd, meta_ytd)
      cdi_r = safe_div.call(cart_ytd, cdi_ytd)
      ipca_r = safe_div.call(cart_ytd, ipca_ytd)
      ima_r = safe_div.call(cart_ytd, ima_ytd)
      ibov_r = safe_div.call(cart_ytd, ibov_ytd)

      acc_data = [
        { label: 'Meta Acumulado', value: meta_ytd, color: C[:warning] },
        { label: 'Rentabilidade Carteira', value: cart_ytd, color: C[:primary] },
        { label: 'IPCA Acumulado', value: ipca_ytd, color: C[:danger] },
        { label: 'CDI Acumulado', value: cdi_ytd, color: C[:success] },
        { label: 'IMA-GERAL Acumulado', value: ima_ytd, color: C[:secondary] },
        { label: 'Ibovespa Acumulado', value: ibov_ytd, color: C[:warning] }
      ]

      relatives = {
        'Meta Acumulado' => safe_div.call(meta_ytd, meta_ytd),
        'Rentabilidade Carteira' => meta_r,
        'IPCA Acumulado' => safe_div.call(ipca_ytd, meta_ytd),
        'CDI Acumulado' => safe_div.call(cdi_ytd, meta_ytd),
        'IMA-GERAL Acumulado' => safe_div.call(ima_ytd, meta_ytd),
        'Ibovespa Acumulado' => safe_div.call(ibov_ytd, meta_ytd)
      }

      draw_section(title: 'Índices Acumulados', info: @reference_date.year.to_s, border: true, spacing: 0) do
        draw_comparison_bars_labeled(acc_data, relatives: relatives, y: pdf.cursor)
      end

      pdf.move_down 14

      draw_section(title: 'Rentabilidade Acumulada', info: 'Tabela', border: true, spacing: 0) do
        acc_rows = [
          ['Indicador', 'Rent. Acumulada', '% em Relação à Meta'],
          ['Carteira', fmt_pct(cart_ytd), "#{fmt_num(relatives['Rentabilidade Carteira'], 3)}%"],
          ['Meta', fmt_pct(meta_ytd), '100,00%'],
          ['CDI', fmt_pct(cdi_ytd), "#{fmt_num(relatives['CDI Acumulado'], 3)}%"],
          ['IPCA', fmt_pct(ipca_ytd), "#{fmt_num(relatives['IPCA Acumulado'], 3)}%"],
          ['IMA-GERAL', fmt_pct(ima_ytd), "#{fmt_num(relatives['IMA-GERAL Acumulado'], 3)}%"],
          ['Ibovespa', fmt_pct(ibov_ytd), "#{fmt_num(relatives['Ibovespa Acumulado'], 3)}%"]
        ]
        styled_table(acc_rows, col_widths: [160, 170, 185])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Chart drawing helpers
  # ---------------------------------------------------------------------------

  # Draws a vertical grouped bar chart with two series per group plus an
  # auto-computed Total column.
  #
  # Each group in +data+ is a three-element array +[label, v1, v2]+.
  # When both values are zero the group slot is still rendered (empty bars)
  # so the X-axis labels remain visible.
  #
  # @param data   [Array<Array>] rows of +[label, numeric, numeric]+
  # @param labels [Array<String>] legend labels (one per series)
  # @param colors [Array<String>] hex color strings (one per series)
  # @param height [Numeric] total chart height in points
  # @param y      [Numeric] Y coordinate of the top of the chart area
  # @return [void]
  def draw_grouped_bar_chart(data:, labels:, colors:, height:, y:, skip_auto_total: false)
    if data.empty?
      pdf.fill_color C[:gray]
      pdf.font('Plus Jakarta Sans', size: 9, style: :italic) do
        pdf.text_box 'Dados não disponíveis para o período', at: [0, y - 20], width: CONTENT_W, align: :center
      end
      return
    end

    plot_data = skip_auto_total ? data[0...-1] : data
    totals = if skip_auto_total
               [data.last[1].to_f, data.last[2].to_f]
             else
               [data.sum { |_, v1, _| v1.to_f }, data.sum { |_, _, v2| v2.to_f }]
             end

    values = plot_data.flat_map { |_, a, b| [a, b] }.map(&:to_f) + totals
    max_val = [values.map(&:abs).max, 0.001].max

    chart_y = y - 8
    baseline = chart_y - height
    n = plot_data.size + 1
    slot_w = (CONTENT_W - 10) / n.to_f
    pair_w = slot_w * 0.84
    gap = 2.0
    bar_w = (pair_w - gap) / 2.0

    pdf.stroke_color C[:border]
    pdf.line_width 0.5
    pdf.stroke_horizontal_line 0, CONTENT_W, at: baseline

    plot_data.each_with_index do |(label, v1, v2), i|
      slot_x = i * slot_w + slot_w * 0.08

      [v1, v2].each_with_index do |val, j|
        val = val.to_f
        bar_h = [(val.abs / max_val * (height - 18)).round(1), height - 18].min
        x = slot_x + j * (bar_w + gap)
        radius = [2, bar_h / 2.0, bar_w / 2.0].min

        pdf.fill_color colors[j]
        pdf.fill_rounded_rectangle [x, baseline + bar_h], bar_w, bar_h, radius

        next if val == 0

        pdf.fill_color C[:body]
        pdf.font('Geist Pixel Square', size: 4) do
          lbl = fmt_pct(val)
          lw = pdf.width_of(lbl)
          pdf.draw_text lbl, at: [[x + (bar_w - lw) / 2.0, 0].max, baseline + bar_h + 2]
        end
      end

      pdf.fill_color C[:muted]
      pdf.font('Geist Pixel Square', size: 4) do
        mlw = pdf.width_of(label.to_s)
        pdf.draw_text label.to_s, at: [slot_x + (pair_w - mlw) / 2.0, baseline - 9]
      end
    end

    slot_x = plot_data.size * slot_w + slot_w * 0.08

    totals.each_with_index do |val, j|
      val = val.to_f
      bar_h = [(val.abs / max_val * (height - 18)).round(1), height - 18].min
      x = slot_x + j * (bar_w + gap)
      radius = [2, bar_h / 2.0, bar_w / 2.0].min

      pdf.fill_color colors[j]
      pdf.fill_rounded_rectangle [x, baseline + bar_h], bar_w, bar_h, radius

      next if val == 0

      pdf.fill_color C[:body]
      pdf.font('Geist Pixel Square', size: 4) do
        lbl = fmt_pct(val)
        lw = pdf.width_of(lbl)
        pdf.draw_text lbl, at: [[x + (bar_w - lw) / 2.0, 0].max, baseline + bar_h + 2]
      end
    end

    pdf.fill_color C[:muted]
    pdf.font('Geist Pixel Square', size: 4) do
      tlw = pdf.width_of('Total')
      pdf.draw_text 'Total', at: [slot_x + (pair_w - tlw) / 2.0, baseline - 9]
    end

    labels.each_with_index do |lbl, i|
      lx = i * 85
      ly = chart_y + 4
      pdf.fill_color colors[i]
      pdf.fill_rounded_rectangle [lx, ly + 7], 10, 7, 1.5
      pdf.fill_color C[:gray]
      pdf.font('Geist Pixel Square', size: 7) { pdf.draw_text lbl, at: [lx + 13, ly + 1] }
    end
  rescue StandardError => e
    Rails.logger.error("Error drawing grouped bar chart: #{e.message}")
  end

  # Renders the portfolio-to-article comparison as a styled Prawn table.
  #
  # Each row shows both the article's own targets and the portfolio's targets
  # side by side. The deviation cell is coloured green (non-negative) or red
  # (negative). The compliance status cell is coloured green or red.
  #
  # @param rows [Array<Hash>] output of {#collect_portfolio_normative_data}
  # @return [void]
  def draw_portfolio_normative_comparison_table(rows)
    return if rows.empty?

    dash = '—'

    header = [
      'Artigo',
      "Benchmark\n(Artigo)",
      "Benchmark\n(Carteira)",
      'Desvio',
      "Mín.\n(Artigo)",
      "Mín.\n(Carteira)",
      "Máx.\n(Artigo)",
      "Máx.\n(Carteira)",
      'Status'
    ]

    body = rows.map do |r|
      [
        r[:display_name],
        r[:article_benchmark] ? "#{fmt_num(r[:article_benchmark], 4)}%" : dash,
        r[:portfolio_benchmark] ? "#{fmt_num(r[:portfolio_benchmark], 4)}%" : dash,
        r[:deviation] ? "#{r[:deviation] >= 0 ? '+' : ''}#{fmt_num(r[:deviation], 4)}%" : dash,
        r[:article_minimum] ? "#{fmt_num(r[:article_minimum], 4)}%" : dash,
        r[:portfolio_minimum] ? "#{fmt_num(r[:portfolio_minimum], 4)}%" : dash,
        r[:article_maximum] ? "#{fmt_num(r[:article_maximum], 4)}%" : dash,
        r[:portfolio_maximum] ? "#{fmt_num(r[:portfolio_maximum], 4)}%" : dash,
        r[:compliant] ? 'CONFORME' : 'ALERTA'
      ]
    end

    table_data = [header] + body

    sanitized = table_data.map do |row|
      row.map { |c| c.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?') }
    end

    col_widths = [120, 45, 50, 44, 40, 44, 40, 44, 48]

    pdf.table(sanitized,
              header: true,
              width: CONTENT_W,
              column_widths: col_widths) do |t|

      t.row(0).tap do |r|
        r.background_color = C[:primary]
        r.text_color = C[:white]
        r.font = 'Plus Jakarta Sans'
        r.size = 7
        r.padding = [5, 6]
        r.borders = %i[top bottom]
        r.border_color = C[:border]
      end

      (1...sanitized.size).each do |ri|
        row = rows[ri - 1]

        t.row(ri).tap do |r|
          r.background_color = C[:white]
          r.font = 'Plus Jakarta Sans'
          r.size = 7
          r.padding = [5, 6]
          r.borders = %i[top bottom]
          r.border_color = C[:border]
          r.text_color = C[:body]
        end

        dev_cell = t.cells[ri, 3]
        dev_cell.font = 'Geist Mono'
        dev_cell.text_color = if row[:deviation].nil?
                                C[:muted]
                              elsif row[:deviation] >= 0
                                C[:success]
                              else
                                C[:danger]
                              end

        status_cell = t.cells[ri, 8]
        status_cell.font = 'Geist Pixel Square'
        status_cell.size = 6
        status_cell.text_color = C[:white]
        status_cell.background_color = row[:compliant] ? C[:success] : C[:danger]
      end
    end
  rescue Prawn::Errors::CannotFit
    pdf.table(sanitized, header: true, width: CONTENT_W) do |t|
      t.row(0).background_color = C[:primary]
      t.row(0).text_color = C[:white]
    end
  rescue StandardError => e
    Rails.logger.error("[draw_portfolio_normative_comparison_table] #{e.message}")
    pdf.move_down 20
  end

  # Draws a single-series vertical bar chart with an automatic Total column.
  #
  # Negative values are rendered in +:danger+ colour. The value label above
  # each bar switches between currency format (>= 1 000 or <= -1 000) and
  # percentage format automatically.
  #
  # @param data       [Array<Array>] rows of +[label, numeric]+
  # @param height     [Numeric] chart height in points
  # @param y          [Numeric] Y coordinate of the chart top
  # @param color      [String]  hex color for positive bars (default: +:primary+)
  # @param show_total [Boolean] whether to render a Total column (default: +true+)
  # @return [void]
  def draw_bar_chart(data:, height:, y:, color: C[:primary], show_total: true)
    if data.empty?
      pdf.fill_color C[:gray]
      pdf.font('Plus Jakarta Sans', size: 9, style: :italic) do
        pdf.text_box 'Dados não disponíveis para o período', at: [0, y - 20], width: CONTENT_W, align: :center
      end
      return
    end

    values = data.map { |_, v| v.to_f }
    max_val = [values.map(&:abs).max, 0.001].max
    chart_y = y - 8
    baseline = chart_y - height
    n = show_total ? data.size + 1 : data.size
    slot_w = (CONTENT_W - 10) / [n, 1].max.to_f

    pdf.stroke_color C[:border]
    pdf.line_width 0.5
    pdf.stroke_horizontal_line 0, CONTENT_W, at: baseline

    data.each_with_index do |(label, val), i|
      val = val.to_f
      bar_h = [(val.abs / max_val * (height - 18)).round(1), height - 18].min
      x = i * slot_w + slot_w * 0.08
      w = slot_w * 0.84
      radius = [2, bar_h / 2.0, w / 2.0].min
      bar_color = val >= 0 ? color : C[:danger]

      pdf.fill_color bar_color
      pdf.fill_rounded_rectangle [x, baseline + bar_h], w, bar_h, radius

      if val != 0
        pdf.fill_color C[:body]
        pdf.font('Geist Pixel Square', size: 4) do
          lbl = val.abs >= 1000 ? fmt_cur(val) : fmt_pct(val)
          lw = pdf.width_of(lbl)
          pdf.draw_text lbl, at: [[x + (w - lw) / 2.0, 0].max, baseline + bar_h + 2]
        end
      end

      pdf.fill_color C[:muted]
      pdf.font('Geist Pixel Square', size: 4) do
        mlw = pdf.width_of(label.to_s)
        pdf.draw_text label.to_s, at: [x + (w - mlw) / 2.0, baseline - 9]
      end
    end

    if show_total
      total_val = values.sum
      x = data.size * slot_w + slot_w * 0.08
      w = slot_w * 0.84
      bar_h = [(total_val.abs / max_val * (height - 18)).round(1), height - 18].min
      radius = [2, bar_h / 2.0, w / 2.0].min
      bar_color = total_val >= 0 ? C[:primary] : C[:danger]

      pdf.fill_color bar_color
      pdf.fill_rounded_rectangle [x, baseline + bar_h], w, bar_h, radius

      pdf.fill_color C[:body]
      pdf.font('Geist Pixel Square', size: 4) do
        lbl = fmt_cur(total_val)
        lw = pdf.width_of(lbl)
        pdf.draw_text lbl, at: [[x + (w - lw) / 2.0, 0].max, baseline + bar_h + 2]
      end

      pdf.fill_color C[:muted]
      pdf.font('Geist Pixel Square', size: 4) do
        tlw = pdf.width_of('Total')
        pdf.draw_text 'Total', at: [x + (w - tlw) / 2.0, baseline - 9]
      end
    end
  rescue StandardError => e
    Rails.logger.error("Error drawing bar chart: #{e.message}")
  end

  # Draws a waterfall (cascade) chart representing cumulative net cash flows.
  #
  # Each bar starts at the running cumulative total of all previous periods.
  # Positive flows are rendered in +:success+ colour; negative flows in
  # +:danger+. A dashed connector line links each bar to the next. The final
  # column (Total) always starts from zero.
  #
  # @param flows  [Array<Hash>] each element must have +:period+,
  #   +:applications+, and +:redemptions+ keys
  # @param height [Numeric] chart area height in points
  # @param y      [Numeric] Y coordinate of the top of the chart area
  # @return [void]
  def draw_waterfall_chart(flows:, height:, y:)
    return if flows.empty?

    net_values = flows.map { |f| (f[:applications] - f[:redemptions]).to_f }
    total_net = net_values.sum

    running = 0.0
    segments = flows.each_with_index.map do |f, i|
      net = net_values[i]
      base = running
      running += net
      { period: f[:period], net: net, base: base, end_val: running }
    end

    all_vals = segments.flat_map { |s| [s[:base], s[:end_val]] } + [0, total_net]
    y_min = [all_vals.min, 0].min
    y_max = [all_vals.max, 0].max
    y_range = (y_max - y_min).nonzero? || 1.0
    usable_h = height - 18
    chart_y = y - 8
    baseline = chart_y - height
    n = segments.size + 1
    slot_w = (CONTENT_W - 10) / [n, 1].max.to_f

    to_px = ->(val) { baseline + ((val - y_min) / y_range * usable_h) }

    pdf.stroke_color C[:border]
    pdf.line_width 0.5
    pdf.stroke_horizontal_line 0, CONTENT_W, at: to_px.call(0)
    pdf.stroke_horizontal_line 0, CONTENT_W, at: baseline

    segments.each_with_index do |seg, i|
      net = seg[:net]
      x = i * slot_w + slot_w * 0.08
      w = slot_w * 0.84
      y_bottom = to_px.call([seg[:base], seg[:end_val]].min)
      y_top = to_px.call([seg[:base], seg[:end_val]].max)
      bh = [y_top - y_bottom, 1].max
      radius = [2, bh / 2.0, w / 2.0].min

      pdf.fill_color net >= 0 ? C[:success] : C[:danger]
      pdf.fill_rounded_rectangle [x, y_bottom + bh], w, bh, radius

      if i < segments.size - 1
        connector_y = to_px.call(seg[:end_val])
        next_x = (i + 1) * slot_w

        pdf.stroke_color C[:muted]
        pdf.line_width 0.4
        pdf.dash(2, space: 2)
        pdf.stroke_horizontal_line x + w, next_x + slot_w * 0.08, at: connector_y
        pdf.undash
      end

      pdf.fill_color C[:body]
      pdf.font('Geist Pixel Square', size: 4) do
        val_label = fmt_cur(net)
        lw = pdf.width_of(val_label)
        lx = [x + (w - lw) / 2.0, 0].max
        ly = y_top + 2
        pdf.draw_text val_label, at: [lx, ly]
      end

      pdf.fill_color C[:muted]
      pdf.font('Geist Pixel Square', size: 4) do
        ml = short_month(seg[:period])[0..2]
        mlw = pdf.width_of(ml)
        pdf.draw_text ml, at: [x + (w - mlw) / 2.0, baseline - 9]
      end
    end

    x = segments.size * slot_w + slot_w * 0.08
    w = slot_w * 0.84
    y_bottom = to_px.call([0, total_net].min)
    y_top = to_px.call([0, total_net].max)
    bh = [y_top - y_bottom, 1].max
    radius = [2, bh / 2.0, w / 2.0].min

    pdf.fill_color C[:primary]
    pdf.fill_rounded_rectangle [x, y_bottom + bh], w, bh, radius

    pdf.fill_color C[:body]
    pdf.font('Geist Pixel Square', size: 4) do
      val_label = fmt_cur(total_net)
      lw = pdf.width_of(val_label)
      lx = [x + (w - lw) / 2.0, 0].max
      ly = y_top + 2
      pdf.draw_text val_label, at: [lx, ly]
    end

    pdf.fill_color C[:muted]
    pdf.font('Geist Pixel Square', size: 4) do
      tl = 'Total'
      tlw = pdf.width_of(tl)
      pdf.draw_text tl, at: [x + (w - tlw) / 2.0, baseline - 9]
    end

    [[C[:success], 'Aumentar'], [C[:danger], 'Diminuir'], [C[:primary], 'Total']].each_with_index do |(clr, lbl), i|
      lx = i * 85
      ly = chart_y + 4
      pdf.fill_color clr
      pdf.fill_rounded_rectangle [lx, ly + 7], 10, 7, 1.5
      pdf.fill_color C[:gray]
      pdf.font('Geist Pixel Square', size: 7) { pdf.draw_text lbl, at: [lx + 13, ly + 1] }
    end
  rescue StandardError => e
    Rails.logger.error("Error drawing waterfall chart: #{e.message}")
  end

  # Draws a simple vertical bar chart representing monthly earnings.
  #
  # Positive bars are rendered in +:secondary+ colour; negative bars in
  # +:danger+. A Total column summarising all values is appended on the right.
  #
  # @param data   [Array<Array>] rows of +[month_label, earnings_float]+
  # @param height [Numeric] chart area height in points
  # @param y      [Numeric] Y coordinate of the top of the chart area
  # @return [void]
  def draw_earnings_waterfall(data:, height:, y:)
    return if data.empty?

    total = data.sum { |_, v| v.to_f }
    values = data.map { |_, v| v.to_f }
    max_val = [values.map(&:abs).max, 0.001].max

    chart_y = y - 8
    baseline = chart_y - height
    n = data.size + 1
    slot_w = (CONTENT_W - 10) / n.to_f

    pdf.stroke_color C[:border]
    pdf.line_width 0.5
    pdf.stroke_horizontal_line 0, CONTENT_W, at: baseline

    data.each_with_index do |(label, val), i|
      val = val.to_f
      bar_h = [(val.abs / max_val * (height - 18)).round(1), height - 18].min
      x = i * slot_w + slot_w * 0.08
      w = slot_w * 0.84
      radius = [2, bar_h / 2.0, w / 2.0].min
      bar_color = val >= 0 ? C[:secondary] : C[:danger]

      pdf.fill_color bar_color
      pdf.fill_rounded_rectangle [x, baseline + bar_h], w, bar_h, radius

      pdf.fill_color C[:body]
      pdf.font('Geist Pixel Square', size: 4) do
        lbl = fmt_cur(val)
        lw = pdf.width_of(lbl)
        pdf.draw_text lbl, at: [[x + (w - lw) / 2.0, 0].max, baseline + bar_h + 2]
      end

      pdf.fill_color C[:muted]
      pdf.font('Geist Pixel Square', size: 4) do
        mlw = pdf.width_of(label)
        pdf.draw_text label, at: [x + (w - mlw) / 2.0, baseline - 9]
      end
    end

    x = data.size * slot_w + slot_w * 0.08
    w = slot_w * 0.84
    bar_h = [(total.abs / max_val * (height - 18)).round(1), height - 18].min
    radius = [2, bar_h / 2.0, w / 2.0].min

    pdf.fill_color C[:success]
    pdf.fill_rounded_rectangle [x, baseline + bar_h], w, bar_h, radius

    pdf.fill_color C[:body]
    pdf.font('Geist Pixel Square', size: 4) do
      lbl = fmt_cur(total)
      lw = pdf.width_of(lbl)
      pdf.draw_text lbl, at: [[x + (w - lw) / 2.0, 0].max, baseline + bar_h + 2]
    end

    pdf.fill_color C[:muted]
    pdf.font('Geist Pixel Square', size: 4) do
      tlw = pdf.width_of('Total')
      pdf.draw_text 'Total', at: [x + (w - tlw) / 2.0, baseline - 9]
    end

    [[C[:secondary], 'Aumentar'], [C[:danger], 'Diminuir'], [C[:success], 'Total']].each_with_index do |(clr, lbl), i|
      lx = i * 85
      ly = chart_y + 4
      pdf.fill_color clr
      pdf.fill_rounded_rectangle [lx, ly + 7], 10, 7, 1.5
      pdf.fill_color C[:gray]
      pdf.font('Geist Pixel Square', size: 7) { pdf.draw_text lbl, at: [lx + 13, ly + 1] }
    end
  rescue StandardError => e
    Rails.logger.error("draw_earnings_waterfall: #{e.message}")
  end

  # Draws a semi-circular gauge (speedometer) representing a percentage value
  # against a defined maximum.
  #
  # The arc spans 180° (left) to 0° (right) in the Prawn coordinate system.
  # A white dividing line at the 100% mark (90° = top) visually separates
  # the "below target" and "above target" halves.
  #
  # @param value  [Float]  the value to display (e.g. 164.02 for 164.02%)
  # @param max    [Float]  the scale maximum (default: 200.0)
  # @param cx     [Float]  center X of the arc in points
  # @param cy     [Float]  center Y of the arc in points
  # @param radius [Float]  outer radius of the gauge in points
  # @return [void]
  def draw_gauge_meter(value:, max: 200.0, cx:, cy:, radius: 65)
    hole_ratio = 0.55
    inner_r = radius * hole_ratio
    steps = 80
    bg_color = 'e8e8e8'
    fill_color = 'd8db00'
    start_deg = 180.0
    end_deg = 0.0

    build_arc = lambda do |from_deg, to_deg, r_outer, r_inner, n|
      outer = n.times.map do |i|
        a = (from_deg + (to_deg - from_deg) * i / (n - 1).to_f) * Math::PI / 180.0
        [cx + r_outer * Math.cos(a), cy + r_outer * Math.sin(a)]
      end
      inner = n.times.map do |i|
        a = (to_deg - (to_deg - from_deg) * i / (n - 1).to_f) * Math::PI / 180.0
        [cx + r_inner * Math.cos(a), cy + r_inner * Math.sin(a)]
      end
      outer + inner
    end

    pdf.fill_color bg_color
    pdf.fill_polygon(*build_arc.call(start_deg, end_deg, radius, inner_r, steps))

    clamped = [[value.to_f, 0].max, max].min
    fill_ratio = clamped / max
    fill_end = start_deg + (end_deg - start_deg) * fill_ratio

    if fill_ratio > 0.005
      pdf.fill_color fill_color
      pdf.fill_polygon(*build_arc.call(start_deg, fill_end, radius, inner_r, [steps, 3].max))
    end

    half_x = cx + radius * Math.cos(Math::PI / 2)
    half_y = cy + radius * Math.sin(Math::PI / 2)
    in_x = cx + inner_r * Math.cos(Math::PI / 2)
    in_y = cy + inner_r * Math.sin(Math::PI / 2)

    pdf.stroke_color C[:white]
    pdf.line_width 1.2
    pdf.stroke_line [in_x, in_y], [half_x, half_y]

    pdf.fill_color C[:white]
    pdf.fill_polygon(*build_arc.call(start_deg, end_deg, inner_r, 0.01, steps))

    val_str = "#{fmt_num(value.to_f, 2)}%"
    pdf.fill_color C[:body]
    pdf.font('Geist Pixel Square', size: 13) do
      vw = pdf.width_of(val_str)
      pdf.draw_text val_str, at: [cx - vw / 2.0, cy - 14]
    end

    pdf.fill_color C[:muted]
    pdf.font('Geist Pixel Square', size: 6) do
      pdf.draw_text '0,00%', at: [cx - radius - 2, cy - 14]
      pdf.draw_text "#{fmt_num(max, 2)}%", at: [cx + inner_r + 4, cy - 14]
    end
  rescue StandardError => e
    Rails.logger.error("draw_gauge_meter: #{e.message}")
  end

  # Draws fund allocation as proportional horizontal bars, one per fund.
  #
  # A maximum of 12 funds are rendered to prevent overflow. Each bar is
  # coloured from the +:chart+ palette in order.
  #
  # @param alloc [Array<Hash>] allocation data (see {#calculate_allocation_data})
  # @param y     [Numeric] starting Y coordinate in points
  # @return [void]
  def draw_allocation_bars(alloc, y:)
    return pdf.move_down(40) if alloc.empty?

    max_alloc = alloc.map { |a| a[:allocation].to_f }.max.nonzero? || 1.0
    bar_h = 18
    spacing = 20
    label_w = 160

    alloc.first(12).each_with_index do |item, i|
      by = y - i * spacing - 16
      alloc_f = item[:allocation].to_f
      bar_w = (alloc_f / max_alloc * (CONTENT_W - 200)).round(1)
      color = C[:chart][i % C[:chart].size]
      radius = [2, (bar_h - 4) / 2.0].min

      pdf.fill_color C[:gray_dark]
      pdf.font('Geist Pixel Square', size: 7) { pdf.draw_text truncate(item[:fund_name].to_s, 28), at: [0, by + 6] }

      pdf.fill_color color
      pdf.fill_rounded_rectangle [label_w, by + bar_h - 2], [bar_w, 1].max, bar_h - 4, radius

      pdf.fill_color C[:gray]
      pdf.font('Geist Pixel Square', size: 7) { pdf.draw_text "#{fmt_num(alloc_f, 2)}%", at: [label_w + bar_w + 4, by + 6] }

      break if by < 20
    end

    pdf.move_down([alloc.size, 12].min * spacing + 10)
  rescue StandardError => e
    Rails.logger.error("Error drawing allocation bars: #{e.message}")
    pdf.move_down 40
  end

  # Draws a set of horizontal bars scaled to the maximum value in +data+.
  #
  # At most 8 items are rendered to prevent overflow. Values are formatted
  # as currency.
  #
  # @param data  [Array<Hash>] each element must have +:label+ and +:value+
  # @param color [String] hex color for all bars
  # @param y     [Numeric] starting Y coordinate in points
  # @return [void]
  def draw_horizontal_bars(data:, color:, y:)
    if data.empty?
      pdf.fill_color C[:gray]
      pdf.font('Plus Jakarta Sans', size: 9, style: :italic) do
        pdf.text_box 'Dados não disponíveis', at: [0, y - 20], width: CONTENT_W, align: :center
      end
      pdf.move_down 40
      return
    end

    max_val = data.map { |d| d[:value].to_f.abs }.max.nonzero? || 1.0  # ← .abs para negativos não quebrarem a escala
    label_w = 170
    bar_h = 18
    spacing = 22

    data.first(8).each_with_index do |item, i|
      by = y - i * spacing - 16
      bar_w = (item[:value].to_f.abs / max_val * (CONTENT_W - 230)).round(1)  # ← .abs na largura
      radius = [2, (bar_h - 4) / 2.0].min
      bar_color = item[:value].to_f < 0 ? C[:danger] : color  # ← vermelho para negativos

      pdf.fill_color C[:gray_dark]
      pdf.font('Geist Pixel Square', size: 7) { pdf.draw_text truncate(item[:label].to_s, 26), at: [0, by + 6] }

      pdf.fill_color bar_color
      pdf.fill_rounded_rectangle [label_w, by + bar_h - 2], [bar_w, 1].max, bar_h - 4, radius

      pdf.fill_color item[:value].to_f < 0 ? C[:danger] : C[:gray]  # ← label também em vermelho
      pdf.font('Geist Pixel Square', size: 7) { pdf.draw_text fmt_cur(item[:value]), at: [label_w + bar_w + 4, by + 6] }

      break if by < 20
    end

    pdf.move_down([data.size, 8].min * spacing + 10)
  rescue StandardError => e
    Rails.logger.error("Error drawing horizontal bars: #{e.message}")
    pdf.move_down 40
  end

  # Draws horizontal bars grouped by normative article for the investment
  # policy compliance chart.
  #
  # Four groups are plotted on a shared X axis: Mínimo, Máximo, Alvo, and
  # Carteira atual. Tick marks and percentage labels are drawn on the X axis.
  # A colour-coded legend for each article is appended below the chart.
  #
  # @param articles [Array<Hash>] policy data (see {#collect_investment_policy_data})
  # @param y        [Numeric] Y coordinate of the chart top
  # @return [void]
  def draw_horizontal_policy_chart(articles:, y:)
    return if articles.empty?

    label_w = 80
    chart_w = CONTENT_W - label_w - 30
    bar_h = 10
    bar_gap = 3
    group_gap = 18
    groups = ['Mínimo', 'Máximo', 'Alvo', 'Carteira atual']
    art_colors = [C[:primary], C[:secondary]] + C[:chart]

    all_vals = articles.flat_map { |a| [a[:minimo], a[:maximo], a[:alvo], a[:carteira_atual]] }
    x_max = (([all_vals.max.to_f, 1.0].max * 1.15).round(0) / 10.0).ceil * 10.0

    n_arts = articles.size
    group_h = n_arts * (bar_h + bar_gap) - bar_gap + 4
    total_h = groups.size * group_h + (groups.size - 1) * group_gap + 30

    chart_top = y - 10
    chart_left = label_w
    chart_bottom = chart_top - total_h
    tick_vals = 9.times.map { |i| (x_max / 8.0 * i).round(1) }

    pdf.save_graphics_state do
      tick_vals.each do |tv|
        tx = chart_left + (tv / x_max * chart_w)
        pdf.stroke_color C[:border]; pdf.line_width 0.3
        pdf.stroke_vertical_line chart_bottom, chart_top, at: tx
        pdf.fill_color C[:muted]
        pdf.font('Geist Pixel Square', size: 5) do
          lbl = "#{fmt_num(tv, 2)}%"
          pdf.draw_text lbl, at: [tx - pdf.width_of(lbl) / 2, chart_bottom - 9]
        end
      end
    end

    pdf.stroke_color C[:border]; pdf.line_width 0.5
    pdf.stroke_horizontal_line chart_left, chart_left + chart_w, at: chart_bottom

    groups.each_with_index do |grp_label, gi|
      gy = chart_top - gi * (group_h + group_gap)

      pdf.fill_color C[:body]
      pdf.font('Plus Jakarta Sans', size: 8) do
        lw = pdf.width_of(grp_label)
        pdf.draw_text grp_label, at: [label_w - lw - 6, gy - (group_h / 2.0) + 4]
      end

      articles.each_with_index do |art, ai|
        val = case grp_label
              when 'Mínimo' then art[:minimo]
              when 'Máximo' then art[:maximo]
              when 'Alvo' then art[:alvo]
              when 'Carteira atual' then art[:carteira_atual]
              end

        by = gy - ai * (bar_h + bar_gap)
        bar_w = [x_max > 0 ? (val.to_f / x_max * chart_w) : 0, 0.5].max
        radius = [(bar_h - 2) / 2.0, 2].min

        pdf.fill_color art_colors[ai % art_colors.size]
        pdf.fill_rounded_rectangle [chart_left, by], [bar_w, chart_w].min, bar_h - 1, radius

        pdf.fill_color C[:body]
        pdf.font('Geist Pixel Square', size: 5) do
          pdf.draw_text "#{fmt_num(val.to_f, 2)}%", at: [chart_left + bar_w + 3, by - 6]
        end
      end
    end

    legend_y = chart_bottom - 20
    articles.each_with_index do |art, i|
      lx = i * ((CONTENT_W - label_w) / [articles.size, 1].max) + label_w
      pdf.fill_color art_colors[i % art_colors.size]
      pdf.fill_rounded_rectangle [lx, legend_y + 7], 10, 7, 1.5
      pdf.fill_color C[:gray]
      pdf.font('Geist Pixel Square', size: 6.5) { pdf.draw_text truncate(art[:article_number], 22), at: [lx + 13, legend_y + 1] }
    end

    pdf.move_down total_h + 40
  rescue StandardError => e
    Rails.logger.error("Error drawing horizontal policy chart: #{e.message}")
    pdf.move_down 40
  end

  # Draws horizontal bars scaled by category value for asset type charts.
  #
  # Bars are coloured using +category_colors+; unmapped categories fall back
  # to a neutral dark colour.
  #
  # @param asset_groups    [Hash{String => Hash}] category → value/earnings hash
  # @param value_key       [Symbol] either +:value+ or +:earnings+
  # @param format          [Symbol] +:currency+ or +:percent+
  # @param category_colors [Hash{String => String}] category → hex color
  # @return [void]
  def draw_asset_type_bars(asset_groups:, value_key:, format:, category_colors:)
    label_w = 130
    bar_area = CONTENT_W - label_w - 70
    bar_h = 16
    gap = 28
    max_val = asset_groups.values.map { |v| v[value_key].to_f }.max.nonzero? || 1.0

    asset_groups.sort_by { |_, v| -v[value_key].to_f }.each_with_index do |(category_label, vals), i|
      val = vals[value_key].to_f
      bar_w = [((val.abs / max_val) * bar_area).round(1), val != 0 ? 1.0 : 0].max
      color = category_colors[category_label] || '607d8b'
      by = pdf.cursor - (i * gap) - bar_h

      pdf.fill_color '666666'
      pdf.font('Geist Pixel Square', size: 7) { pdf.draw_text truncate(category_label, 22), at: [0, by + 4] }

      pdf.fill_color color
      pdf.fill_rounded_rectangle [label_w, by + bar_h], [bar_w, 0.5].max, bar_h - 2, 2

      pdf.fill_color '666666'
      pdf.font('Geist Pixel Square', size: 7) do
        lbl = format == :currency ? fmt_cur(val) : fmt_pct(val)
        pdf.draw_text lbl, at: [label_w + bar_w + 5, by + 4]
      end
    end

    pdf.move_down asset_groups.size * gap + 8
  rescue StandardError => e
    Rails.logger.error("draw_asset_type_bars: #{e.message}")
    pdf.move_down 40
  end

  # Draws a donut chart with percentage labels inside each slice and a
  # coloured legend to the right.
  #
  # Slices smaller than 4% do not render a percentage label to avoid
  # crowding. A small gap between slices (+gap_deg+) adds visual separation.
  #
  # @param data       [Array<Hash>] each element must have +:label+ and +:value+;
  #   an optional +:color+ key overrides the default palette entry
  # @param cx         [Numeric] center X in points
  # @param cy         [Numeric] center Y in points
  # @param radius     [Numeric] outer radius in points
  # @param hole_ratio [Float]  ratio of inner to outer radius (default: 0.55)
  # @param legend_x   [Numeric, nil] legend X origin; defaults to +cx + radius + 16+
  # @param legend_y   [Numeric, nil] legend Y origin; defaults to +cy + radius/2+
  # @param gap_deg    [Float]  gap between slices in degrees (default: 1.5)
  # @return [void]
  def draw_donut_chart(data:, cx:, cy:, radius:, hole_ratio: 0.55, legend_x: nil, legend_y: nil, gap_deg: 1.5)
    return if data.empty?

    total = data.sum { |d| d[:value].to_f }
    return if total <= 0

    colors = C[:chart]
    steps = 60
    start_angle = 90.0

    data.each_with_index do |item, i|
      pct = item[:value].to_f / total
      next if pct <= 0

      sweep = [pct * 360.0 - gap_deg, 0.1].max
      end_angle = start_angle - sweep
      color = item[:color] || colors[i % colors.size]
      n_steps = [(pct * steps).ceil, 2].max
      angles = n_steps.times.map { |j| start_angle - (sweep * j / (n_steps - 1).to_f) }

      points = [[cx, cy]] + angles.map do |a|
        rad = a * Math::PI / 180.0
        [cx + radius * Math.cos(rad), cy + radius * Math.sin(rad)]
      end

      pdf.fill_color color
      pdf.fill_polygon(*points)

      if pct >= 0.04
        mid_rad = ((start_angle + end_angle) / 2.0) * Math::PI / 180.0
        lr = radius * 0.73
        lx = cx + lr * Math.cos(mid_rad)
        ly = cy + lr * Math.sin(mid_rad)
        pdf.fill_color C[:white]
        pdf.font('Geist Pixel Square', size: 0) do
          lbl = "#{fmt_num(pct * 100, 2)}%"
          lw = pdf.width_of(lbl)
          pdf.draw_text lbl, at: [lx - lw / 2.0, ly - 3]
        end
      end

      start_angle = end_angle - gap_deg
    end

    pdf.fill_color C[:white]
    pdf.fill_circle [cx, cy], radius * hole_ratio

    lx = legend_x || (cx + radius + 16)
    ly = legend_y || (cy + radius / 2.0)
    line_h = 16
    legend_text_x = lx + 14
    legend_text_w = CONTENT_W - legend_text_x

    data.each_with_index do |item, i|
      pct = item[:value].to_f / total
      color = item[:color] || colors[i % colors.size]
      iy = ly - i * line_h

      pdf.fill_color color
      pdf.fill_circle [lx + 5, iy + 4], 4.5
      pdf.fill_color C[:muted]
      pdf.font('Geist Pixel Square', size: 7) do
        label_text = if item[:display_value]
                       "#{fmt_num(pct * 100, 2)}% -- #{item[:label]}  #{item[:display_value]}"
                     else
                       "#{fmt_num(pct * 100, 2)}% -- #{item[:label]}"
                     end
        pdf.text_box label_text,
                     at: [legend_text_x, iy + 16],
                     width: [legend_text_w, 10].max,
                     height: line_h,
                     overflow: :shrink_to_fit,
                     valign: :bottom
      end
    end
  rescue StandardError => e
    Rails.logger.error("draw_donut_chart: #{e.message}")
  end

  # Draws overlapping compliance bars for each normative article in
  # +compliance+: a Carteira Atual bar and an Alvo bar, plus optional dashed
  # Mínimo/Máximo tick marks and a conformity icon.
  #
  # @param compliance [Hash{String => Hash}] see {#calculate_policy_compliance}
  # @param y          [Numeric] starting Y coordinate in points
  # @return [void]
  def draw_policy_compliance_bars(compliance, y:)
    return if compliance.empty?

    bar_h = 10
    group_gap = 28
    label_w = 160
    bar_area = CONTENT_W - label_w - 50
    colors = C[:chart]
    all_pcts = compliance.values.flat_map { |v| [v[:current], v[:target], v[:min], v[:max]].compact }
    max_pct = [all_pcts.max.to_f, 100.0].max
    cur_y = y - 4

    compliance.each_with_index do |(_, v), idx|
      color = colors[idx % colors.size]
      mid_y = cur_y - idx * group_gap

      cart_w = (v[:current] / max_pct * bar_area).round(1)
      pdf.fill_color C[:danger]
      pdf.fill_rounded_rectangle [label_w, mid_y], [cart_w, 1].max, bar_h, [2, bar_h / 2.0].min
      pdf.fill_color C[:body]
      pdf.font('Geist Pixel Square', size: 6) { pdf.draw_text "#{fmt_num(v[:current], 2)}%", at: [label_w + cart_w + 3, mid_y - bar_h + 3] }

      if v[:target] > 0
        tgt_w = (v[:target] / max_pct * bar_area).round(1)
        pdf.fill_color color
        pdf.fill_rounded_rectangle [label_w, mid_y - bar_h - 2], [tgt_w, 1].max, bar_h, [2, bar_h / 2.0].min
        pdf.fill_color C[:body]
        pdf.font('Geist Pixel Square', size: 6) { pdf.draw_text "#{fmt_num(v[:target], 2)}%", at: [label_w + tgt_w + 3, mid_y - bar_h - 2 - bar_h + 3] }
      end

      if v[:min]
        min_x = label_w + (v[:min] / max_pct * bar_area).round(1)
        pdf.stroke_color C[:muted]; pdf.line_width 0.6; pdf.dash(1.5, space: 1.5)
        pdf.stroke_vertical_line mid_y - bar_h * 2 - 4, mid_y + 2, at: min_x
        pdf.undash
        pdf.fill_color C[:muted]
        pdf.font('Geist Pixel Square', size: 5) { pdf.draw_text "Mín #{fmt_num(v[:min], 0)}%", at: [min_x - 10, mid_y + 4] }
      end

      if v[:max]
        max_x = label_w + (v[:max] / max_pct * bar_area).round(1)
        pdf.stroke_color C[:muted]; pdf.line_width 0.6; pdf.dash(1.5, space: 1.5)
        pdf.stroke_vertical_line mid_y - bar_h * 2 - 4, mid_y + 2, at: max_x
        pdf.undash
        pdf.fill_color C[:muted]
        pdf.font('Geist Pixel Square', size: 5) { pdf.draw_text "Máx #{fmt_num(v[:max], 0)}%", at: [max_x - 10, mid_y + 4] }
      end

      icon_color = v[:within_range] ? C[:success] : C[:danger]
      pdf.fill_color icon_color
      pdf.font('Geist Pixel Square', size: 7) { pdf.draw_text v[:within_range] ? '●' : '▲', at: [CONTENT_W - 12, mid_y - bar_h + 1] }

      pdf.fill_color C[:gray_dark]
      pdf.font('Geist Pixel Square', size: 6.5) { pdf.draw_text truncate(v[:display_name], 28), at: [0, mid_y - bar_h + 1] }
    end

    bottom_y = y - compliance.size * group_gap - 4
    [0, 25, 50, 75, 100].each do |pct|
      next if pct > max_pct
      tick_x = label_w + (pct / max_pct * bar_area).round(1)
      pdf.stroke_color C[:border]; pdf.line_width 0.4
      pdf.stroke_vertical_line bottom_y, y + 2, at: tick_x
      pdf.fill_color C[:muted]
      pdf.font('Geist Pixel Square', size: 5) { pdf.draw_text "#{pct}%", at: [tick_x - 5, bottom_y - 9] }
    end

    legend_y = bottom_y - 20
    [[C[:danger], 'Carteira Atual'], [C[:chart][0], 'Alvo']].each_with_index do |(lc, ll), li|
      lx = li * 110
      pdf.fill_color lc
      pdf.fill_rounded_rectangle [lx, legend_y + 7], 10, 7, 1.5
      pdf.fill_color C[:gray]
      pdf.font('Geist Pixel Square', size: 7) { pdf.draw_text ll, at: [lx + 13, legend_y + 1] }
    end

    pdf.move_down compliance.size * group_gap + 50
  rescue StandardError => e
    Rails.logger.error("Error drawing policy compliance bars: #{e.message}")
    pdf.move_down 40
  end

  # Draws horizontal comparison bars with a dual value label showing both
  # the absolute accumulated value and its percentage relative to the META.
  #
  # Example label: +"1,29% (164,02%)"+
  #
  # @param items     [Array<Hash>] each with +:label+, +:value+, and +:color+
  # @param relatives [Hash{String => Float}] label → percentage of META
  # @param y         [Numeric] starting Y coordinate in points
  # @return [void]
  def draw_comparison_bars_labeled(items, relatives:, y:)
    label_w = 150
    bar_h = 18
    spacing = 26
    radius = 2
    val_label_w = 110
    bar_area = CONTENT_W - label_w - val_label_w
    max_val = items.map { |i| i[:value].to_f.abs }.max.nonzero? || 1.0

    items.each_with_index do |item, i|
      by = y - i * spacing - 16
      bar_w = (item[:value].to_f.abs / max_val * bar_area).round(1)
      rel = relatives[item[:label]].to_f
      label = rel > 0 ? "#{fmt_pct(item[:value])} (#{fmt_num(rel, 2)}%)" : fmt_pct(item[:value])

      pdf.fill_color C[:muted]
      pdf.font('Geist Pixel Square', size: 8) do
        pdf.text_box item[:label].to_s,
                     at: [0, by + bar_h],
                     width: label_w - 4,
                     height: bar_h,
                     overflow: :shrink_to_fit,
                     valign: :center
      end

      pdf.fill_color item[:color]
      pdf.fill_rounded_rectangle [label_w, by + bar_h - 2], [bar_w, 1].max, bar_h - 4, [radius, (bar_h - 4) / 2.0].min

      pdf.fill_color C[:muted]
      pdf.font('Geist Pixel Square', size: 8) do
        pdf.text_box label,
                     at: [label_w + bar_w + 4, by + bar_h],
                     width: val_label_w,
                     height: bar_h,
                     overflow: :shrink_to_fit,
                     valign: :center
      end
    end

    pdf.move_down items.size * spacing + 10
  rescue StandardError => e
    Rails.logger.error("draw_comparison_bars_labeled: #{e.message}")
    pdf.move_down 40
  end

  # ---------------------------------------------------------------------------
  # Legend helpers
  # ---------------------------------------------------------------------------

  # Draws the "Enquadramento 5.272/25" compliance legend with colour-coded
  # dots for Item I and Item II.
  #
  # Used below the patrimony-by-index and asset-type charts.
  #
  # @return [void]
  def draw_compliance_legend
    legend_y = pdf.cursor - 4
    pdf.fill_color C[:muted]
    pdf.font('Plus Jakarta Sans', size: 7) { pdf.draw_text 'Enquadramento 5.272/25', at: [0, legend_y] }

    x_offset = 120
    [{ color: C[:primary], label: 'Item I' }, { color: C[:secondary], label: 'Item II' }].each do |item|
      pdf.fill_color item[:color]
      pdf.fill_circle [x_offset + 4, legend_y + 3], 3.5
      pdf.fill_color C[:muted]
      pdf.font('Plus Jakarta Sans', size: 7) do
        pdf.draw_text item[:label], at: [x_offset + 12, legend_y]
        x_offset += pdf.width_of(item[:label]) + 30
      end
    end

    pdf.move_down 14
  end

  # Draws a dynamic "Enquadramento" legend populated from the categories
  # actually present in the current chart.
  #
  # @param category_labels [Array<String>] categories to include
  # @param category_colors [Hash{String => String}] category → hex color
  # @return [void]
  def draw_dynamic_enquadramento_legend(category_labels, category_colors)
    legend_y = pdf.cursor - 4
    pdf.fill_color C[:muted]
    pdf.font('Plus Jakarta Sans', size: 7) { pdf.draw_text 'Enquadramento 5.272/25', at: [0, legend_y] }

    x_offset = 120
    category_labels.each do |label|
      color = category_colors[label] || C[:muted]
      pdf.fill_color color
      pdf.fill_circle [x_offset + 4, legend_y + 3], 3.5
      pdf.fill_color C[:muted]
      pdf.font('Plus Jakarta Sans', size: 7) do
        pdf.draw_text label, at: [x_offset + 12, legend_y]
        x_offset += pdf.width_of(label) + 22
      end
    end

    pdf.move_down 14
  end

  # Draws the "Tipo de Ativo" legend used on the investment policy bar charts.
  #
  # @param policy         [Array<Hash>] policy articles
  # @param article_colors [Hash{String => String}] article number → hex color
  # @param default_colors [Array<String>] fallback palette
  # @return [void]
  def draw_policy_legend(policy, article_colors, default_colors)
    legend_items = policy.map.with_index do |art, idx|
      color = article_colors[art[:article_number]] || default_colors[idx % default_colors.size]
      { color: color, label: normalize_category(art[:category]) }
      { color: color, label: art[:label] }
    end
    ly = pdf.cursor
    x = 0
    pdf.fill_color C[:muted]
    pdf.font('Plus Jakarta Sans', size: 6.5) do
      pdf.draw_text 'Artigo', at: [x, ly]
      x += pdf.width_of('Tipo de Ativo') + 10
    end
    legend_items.each do |item|
      pdf.fill_color item[:color]
      pdf.fill_circle [x + 4, ly + 3], 3.5
      pdf.fill_color C[:muted]
      pdf.font('Plus Jakarta Sans', size: 6.5) do
        pdf.draw_text item[:label], at: [x + 11, ly]
        x += pdf.width_of(item[:label]) + 22
      end
    end
    pdf.move_down 10
  end

  # ---------------------------------------------------------------------------
  # Table helper
  # ---------------------------------------------------------------------------

  # Renders a styled Prawn table with a light header row, white body rows,
  # and automatic numeric colouring (green/red/muted) based on cell content.
  #
  # Falls back gracefully on +Prawn::Errors::CannotFit+ by retrying without
  # column width hints, and ultimately falls back to plain pipe-delimited text
  # rows if all else fails.
  #
  # @param rows          [Array<Array>] first row is treated as the header
  # @param col_widths    [Array<Numeric>, nil] explicit column widths in points
  # @param last_row_bold [Boolean] whether the last row receives bold/highlight
  #   styling (default: +false+)
  # @return [void]
  def styled_table(rows, col_widths: nil, last_row_bold: false)
    if rows.size < 2
      pdf.fill_color C[:gray]
      pdf.font('Plus Jakarta Sans', size: 7, style: :italic) do
        pdf.text_box 'Não há dados disponíveis', at: [0, pdf.cursor - 20], width: CONTENT_W, align: :center
      end
      pdf.move_down 40
      return
    end

    sanitized = rows.map do |row|
      row.map { |c| c.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?') }
    end

    base_opts = {
      header: true,
      width: CONTENT_W,
      cell_style: {
        font: 'Plus Jakarta Sans',
        size: 7,
        padding: [6, 8],
        borders: %i[top bottom],
        border_color: C[:border],
        border_width: 1,
        inline_format: true,
        overflow: :shrink_to_fit,
        min_font_size: 7
      }
    }
    base_opts[:column_widths] = col_widths if col_widths

    build = lambda do |opts|
      pdf.table(sanitized, opts) do |t|
        t.row(0).tap do |r|
          r.text_color = C[:body]
          r.background_color = C[:bg_light]
          r.borders = %i[top bottom]
        end

        (1...sanitized.size).each do |ri|
          t.row(ri).background_color = C[:white]
          sanitized[ri].each_with_index do |cell_val, ci|
            cell = t.cells[ri, ci]
            numeric_val = extract_numeric_value(cell_val)
            cell.font = 'Geist Mono'
            cell.text_color = color_for_value(numeric_val)
          end
        end

        if last_row_bold && sanitized.size > 1
          last = sanitized.size - 1
          t.row(last).tap do |r|
            r.background_color = C[:bg_light]
            r.borders = %i[top bottom]
            r.border_color = C[:body]
          end
          sanitized[last].each_with_index do |cell_val, ci|
            cell = t.cells[last, ci]
            if numeric_cell?(cell_val)
              cell.font = 'Geist Pixel Square'
              cell.text_color = color_for_value(extract_numeric_value(cell_val))
            else
              cell.text_color = C[:body]
            end
          end
        end
      end
    end

    build.call(base_opts)
  rescue Prawn::Errors::CannotFit
    begin
      build.call(base_opts.except(:column_widths))
    rescue StandardError
      pdf.font('Plus Jakarta Sans', size: 7) { sanitized.each { |r| pdf.text r.join(' | ') } }
    end
  end

  # ---------------------------------------------------------------------------
  # Table cell helpers
  # ---------------------------------------------------------------------------

  # Returns +true+ if +cell+ contains a recognisable numeric string.
  #
  # Recognised formats:
  # * Brazilian currency: +R$ 1.234,56+
  # * Percentage:         +1,23%+
  # * Plain number:       +1.234,56+
  #
  # @param cell [Object] cell value (converted to String internally)
  # @return [Boolean]
  def numeric_cell?(cell)
    s = cell.to_s.strip
    s =~ /^R\$\s*-?\d+(\.\d{3})*,\d{2}$/ ||
      s =~ /^-?\d+(,\d+)?%$/ ||
      s =~ /^-?\d+(\.\d{3})*(,\d+)?$/
  end

  # Extracts a Float from a Brazilian-formatted numeric string by stripping
  # currency symbols, thousands separators, and converting the decimal comma
  # to a period.
  #
  # @param cell [Object] cell value
  # @return [Float] parsed value, or +0.0+ on parse failure
  def extract_numeric_value(cell)
    cell.to_s.strip.gsub(/[R$\s%]/, '').gsub('.', '').gsub(',', '.').to_f
  rescue
    0.0
  end

  # Returns the appropriate hex color for a numeric value.
  #
  # * Negative  → +:danger+
  # * Zero      → +:muted+
  # * Positive  → +:muted+
  #
  # @param value [Numeric]
  # @return [String] hex color string
  def color_for_value(value)
    if value < 0 then
      C[:danger]
    elsif value == 0 then
      C[:muted]
    else
      C[:muted]
    end
  end

  # Normalises a category label, mapping legacy "Renda Fixa" variants to
  # the canonical "Fundos ou ETF 100% TPF" label.
  #
  # @param category [String, nil]
  # @return [String]
  def normalize_category(category)
    return 'Fundos ou ETF 100% TPF' if category.to_s.match?(/renda fixa/i)
    category.presence || 'Fundos ou ETF 100% TPF'
  end

  # ---------------------------------------------------------------------------
  # Page layout helpers
  # ---------------------------------------------------------------------------

  # Renders a standardised page header consisting of the title in
  # Source Serif 4, a primary-colored rule, and a light-colored secondary rule.
  #
  # @param title [String] the heading text
  # @return [void]
  def page_header(title)
    pdf.pad 10 do
      pdf.font('Source Serif 4', size: 18) do
        text_h = pdf.height_of(title, width: CONTENT_W - 140)
        pdf.text_box title, width: CONTENT_W - 140, height: text_h, overflow: :expand
        pdf.move_down text_h
      end
    end

    pdf.line_width = 1
    pdf.stroke_color C[:secondary]
    pdf.stroke_horizontal_rule

    pdf.move_down 6

    pdf.line_width = 1
    pdf.stroke_color C[:border]
    pdf.stroke_horizontal_rule

    pdf.move_down 24
  end

  # Creates a new PDF page, optionally renders a header, then yields to the
  # caller for content rendering.
  #
  # @param title      [String, nil] page title passed to {#page_header}
  # @param first_page [Boolean] when +true+, skips +start_new_page+ (used for
  #   the very first page of the document)
  # @yield content rendering block
  # @return [void]
  def draw_page(title: nil, first_page: false)
    if first_page
      pdf.go_to_page(1)
    else
      pdf.start_new_page
    end
    page_header(title) if title.present?
    yield if block_given?
  end

  # Renders a labelled content section with an optional right-aligned info
  # tag, a horizontal rule, and bottom spacing.
  #
  # @param title   [String, nil] section title (uppercased)
  # @param info    [String, nil] right-aligned subtitle text
  # @param border  [Boolean] whether to draw the horizontal rule
  # @param spacing [Numeric] vertical space added after the section
  # @yield content rendering block
  # @return [void]
  def draw_section(title: nil, info: nil, border: true, spacing: 20)
    pdf.pad 10 do
      if title
        start_y = pdf.cursor

        pdf.fill_color C[:body]
        pdf.font('Geist Mono', size: 11) { pdf.draw_text title.to_s.upcase, at: [0, start_y] }

        if info
          pdf.fill_color C[:muted]
          pdf.font('Geist Mono', size: 8) do
            info_text = info.to_s.upcase
            info_width = pdf.width_of(info_text)
            pdf.draw_text info_text, at: [CONTENT_W - info_width, start_y]
          end
        end

        pdf.move_down 8
      end

      if border
        pdf.stroke_color C[:border]
        pdf.line_width 1
        pdf.stroke_horizontal_line 0, CONTENT_W, at: pdf.cursor
        pdf.move_down 10
      end
    end

    yield if block_given?
    pdf.move_down spacing
  end

  # ---------------------------------------------------------------------------
  # Series builders
  # ---------------------------------------------------------------------------

  # Builds the 12-slot Carteira monthly return series for the grouped bar
  # chart, covering the rolling 12-month window ending on +@reference_date+.
  #
  # All 12 months are always present. Months without +PerformanceHistory+
  # records produce a zero value so the chart always renders 12 columns.
  #
  # @return [Array<Hash>] 12 elements, each with +:period+, +:value+, +:label+
  def build_monthly_returns_series
    start_date = (@reference_date - 11.months).beginning_of_month

    history_months = data[:monthly_history]
                       .reject { |m| m[:balance] == 0.0 && m[:earnings] == 0.0 }
                       .map { |m| m[:period].beginning_of_month }
                       .to_set

    12.times.map do |i|
      period = (start_date + i.months).beginning_of_month
      ret = history_months.include?(period) ?
              @portfolio.portfolio_return_percentage(period) :
              BigDecimal("0")

      { period: period, value: ret, label: short_month(period) }
    end
  end

  # Builds a 12-slot total patrimony series covering January through December
  # of the reference year, always in calendar order.
  #
  # Months without data produce a zero value so the chart always renders all
  # 12 columns. Uses the +total_patrimony+ lambda defined in the calling page
  # renderer, passed in as a callable.
  #
  # @param total_patrimony [Proc] callable accepting a monthly history Hash
  # @return [Array<Array>] 12 pairs of [month_label, patrimony_float]
  def build_yearly_patrimony_series(total_patrimony:)
    year = @reference_date.year

    hist_by_month = data[:monthly_history]
                      .each_with_object({}) do |m, h|
      h[m[:period].beginning_of_month] = m
    end

    (1..12).map do |month|
      period = Date.new(year, month, 1)
      m = hist_by_month[period]
      value = m ? total_patrimony.(m) : 0.0
      [short_month(period), value]
    end
  end

  # Builds a 12-slot earnings series covering January through December of the
  # reference year, always in calendar order.
  #
  # Months without +PerformanceHistory+ data produce a zero value.
  #
  # @return [Array<Array>] 12 pairs of [month_label, earnings_float]
  def build_yearly_earnings_series
    year = @reference_date.year

    earnings_by_month = data[:monthly_history]
                          .each_with_object({}) do |m, h|
      h[m[:period].beginning_of_month] = m[:earnings]
    end

    (1..12).map do |month|
      period = Date.new(year, month, 1)
      [short_month(period), earnings_by_month[period] || 0.0]
    end
  end

  # Builds the 12-slot Carteira monthly return series for the year-view
  # grouped bar chart, always covering January through December of the
  # reference year in calendar order.
  #
  # Months without +PerformanceHistory+ records produce a zero value.
  #
  # @return [Array<Hash>] 12 elements, each with +:period+, +:value+, +:label+
  def build_yearly_returns_series
    year = @reference_date.year

    history_months = data[:monthly_history]
                       .reject { |m| m[:balance] == 0.0 && m[:earnings] == 0.0 }
                       .map { |m| m[:period].beginning_of_month }
                       .to_set

    (1..12).map do |month|
      period = Date.new(year, month, 1)
      end_date = [period.end_of_month, @reference_date].min

      ret = if history_months.include?(period)
              @portfolio.portfolio_twr_return_on(
                period - 1.day, # ← mesmo padrão dos cards
                end_date
              )
            else
              BigDecimal("0")
            end

      { period: period, value: ret, label: short_month(period) }
    end
  end

  # Builds the 12-slot META monthly series for the year-view grouped bar
  # chart, always covering January through December of the reference year.
  #
  # META for each month = +annual_interest_rate+ + IPCA monthly value.
  # Months with no portfolio activity receive a zero META value so that the
  # two series (Carteira and META) are always in sync.
  #
  # @return [Array<Hash>] 12 elements, each with +:period+, +:value+, +:label+
  def build_yearly_meta_series
    year = @reference_date.year
    monthly_rate = @portfolio.annual_interest_rate.to_f

    history_months = data[:monthly_history]
                       .reject { |m| m[:balance] == 0.0 && m[:earnings] == 0.0 }
                       .map { |m| m[:period].beginning_of_month }
                       .to_set

    (1..12).map do |month|
      period = Date.new(year, month, 1)
      val = history_months.include?(period) ?
              meta_monthly_series[period][:ipca] + monthly_rate :
              0.0

      { period: period, value: val, label: short_month(period) }
    end
  end

  # Builds the 12-slot META monthly series for the rolling-window grouped bar
  # chart.
  #
  # META for each month = +annual_interest_rate+ + IPCA for that month.
  # Only months with portfolio performance data receive a non-zero META value,
  # ensuring the two series are always in sync and empty months show no bars
  # for either series.
  #
  # @return [Array<Hash>] 12 elements, each with +:period+, +:value+, +:label+
  def build_meta_series
    start_date = (@reference_date - 11.months).beginning_of_month
    monthly_rate = @portfolio.annual_interest_rate.to_f

    history_months = data[:monthly_history]
                       .reject { |m| m[:balance] == 0.0 && m[:earnings] == 0.0 }
                       .map { |m| m[:period].beginning_of_month }
                       .to_set

    12.times.map do |i|
      per = (start_date + i.months).beginning_of_month
      val = history_months.include?(per) ?
              meta_monthly_series[per][:ipca] + monthly_rate :
              0.0

      { period: per, value: val, label: short_month(per) }
    end
  end

  # ---------------------------------------------------------------------------
  # Memoised helpers
  # ---------------------------------------------------------------------------

  # Returns a memoised Hash of +{ Date => { ipca: Float, meta: Float } }+
  # covering all 12 months in the rolling window.
  #
  # Avoids N+1 queries by loading all IPCA history in a single query and
  # indexing by +beginning_of_month+. The Hash uses a default block so that
  # any date key not in the loaded data returns zero values gracefully.
  #
  # @return [Hash{Date => Hash}]
  def meta_monthly_series
    @meta_monthly_series ||= begin
                               ipca_index = EconomicIndex.find_by(abbreviation: 'IPCA')
                               monthly_rate = @portfolio.annual_interest_rate.to_f
                               start_date = (@reference_date - 11.months).beginning_of_month

                               ipca_by_month = if ipca_index
                                                 ipca_index.economic_index_histories
                                                           .where(date: start_date..@reference_date.end_of_month)
                                                           .index_by { |h| h.date.beginning_of_month }
                                               else
                                                 {}
                                               end

                               Hash.new do |h, date|
                                 key = date.beginning_of_month
                                 ipca_val = ipca_by_month[key]&.value.to_f || 0.0
                                 h[key] = { ipca: ipca_val, meta: monthly_rate + ipca_val }
                               end
                             end
  end

  # ---------------------------------------------------------------------------
  # Per-fund movement helpers
  # ---------------------------------------------------------------------------

  # Returns total application value for +fi+ within the current reference
  # month.
  #
  # @param fi [FundInvestment]
  # @return [Float]
  def monthly_apps_for(fi)
    fi.applications
      .where(cotization_date: @reference_date.beginning_of_month..@reference_date)
      .sum(:financial_value).to_f
  rescue StandardError
    0.0
  end

  # Returns total redemption value for +fi+ within the current reference
  # month.
  #
  # @param fi [FundInvestment]
  # @return [Float]
  def monthly_reds_for(fi)
    fi.redemptions
      .where(cotization_date: @reference_date.beginning_of_month..@reference_date)
      .sum(:redeemed_liquid_value).to_f
  rescue StandardError
    0.0
  end

  # ---------------------------------------------------------------------------
  # Formatting helpers
  # ---------------------------------------------------------------------------

  # Formats +value+ as Brazilian currency using ActionController helpers.
  #
  # @param value [Numeric]
  # @return [String] e.g. +"R$ 1.234,56"+
  def fmt_cur(value)
    ActionController::Base.helpers.number_to_currency(
      value.to_f, unit: 'R$', separator: ',', delimiter: '.', precision: 2
    )
  end

  # Formats +value+ as a Brazilian percentage string.
  #
  # Uses +BigDecimal+ rounding before conversion to avoid floating-point
  # artefacts.
  #
  # @param value [Numeric]
  # @return [String] e.g. +"1,29%"+
  def fmt_pct(value)
    rounded = BigDecimal(value.to_s).round(2, BigDecimal::ROUND_HALF_UP)
    "#{fmt_num(rounded.to_f, 2)}%"
  end

  # Formats +value+ as a Brazilian decimal number with +decimals+ places.
  #
  # @param value    [Numeric]
  # @param decimals [Integer] number of decimal places (default: 0)
  # @return [String]
  def fmt_num(value, decimals = 0)
    ActionController::Base.helpers.number_with_precision(
      value.to_f, precision: decimals, separator: ',', delimiter: '.'
    )
  end

  # Truncates +text+ to +len+ characters, appending +"…"+ when truncated.
  #
  # @param text [String, nil]
  # @param len  [Integer]
  # @return [String]
  def truncate(text, len)
    text.to_s.length > len ? "#{text[0...len]}…" : text.to_s
  end

  # Returns a full Portuguese date string, e.g. +"15 de janeiro de 2025"+.
  #
  # @param date [Date]
  # @return [String]
  def format_date_full(date)
    "#{date.day} de #{I18n.l(date, format: '%B')} de #{date.year}"
  end

  # Returns a short, capitalised month abbreviation, e.g. +"Jan"+.
  #
  # Falls back to strftime on I18n errors.
  #
  # @param date [Date]
  # @return [String]
  def short_month(date)
    I18n.l(date.to_date, format: '%b').capitalize
  rescue StandardError
    date.strftime('%b')
  end

  # Returns a full month-and-year label, e.g. +"Janeiro de 2025"+.
  #
  # @param date [Date]
  # @return [String]
  def full_month(date)
    I18n.l(date.to_date, format: '%B de %Y').capitalize
  rescue StandardError
    date.strftime('%B de %Y')
  end

  # Returns the month-year label for the current reference date,
  # e.g. +"Janeiro de 2025"+.
  #
  # @return [String]
  def month_year_label
    I18n.l(@reference_date, format: '%B de %Y').capitalize
  rescue StandardError
    @reference_date.strftime('%B de %Y')
  end
end
