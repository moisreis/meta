# frozen_string_literal: true

# ============================================================
#  PortfolioMonthlyReportGenerator
#
#  Generates a multi-page A4 Portrait PDF monthly report for
#  an investment portfolio, following the Meta Investimentos
#  visual identity.
#
#  Usage:
#    generator = PortfolioMonthlyReportGenerator.new(portfolio, Date.current.end_of_month)
#    pdf_bytes  = generator.generate
# ============================================================
class PortfolioMonthlyReportGenerator
  require 'prawn'
  require 'prawn/table'
  require 'bigdecimal'

  # ── colour palette ──────────────────────────────────────────
  C = {
    primary:      '1e3a8a',
    secondary:    '3b82f6',
    accent:       '0ea5e9',
    success:      '10b981',
    danger:       'ef4444',
    warning:      'f59e0b',
    gray_dark:    '374151',
    gray:         '6b7280',
    gray_light:   '9ca3af',
    bg_light:     'f3f4f6',
    bg_blue:      'eff6ff',
    white:        'ffffff',
    border:       'e5e7eb',
    chart:        %w[1e3a8a 3b82f6 0ea5e9 10b981 f59e0b ef4444
                     7c3aed db2777 065f46 92400e 1e40af 7dd3fc]
  }.freeze

  PAGE_W    = 595.28
  PAGE_H    = 841.89
  MARGIN_T  = 40
  MARGIN_B  = 70
  MARGIN_LR = 40
  CONTENT_W = PAGE_W - MARGIN_LR * 2

  PHONE   = '(74) 981-399-579'
  EMAIL   = 'Mr.investing@outlook.com'
  SITE    = 'www.investingmeta.com.br'
  COMPANY = 'META CONSULTORIA DE INVESTIMENTOS INSTITUCIONAIS'
  CNPJ    = '00.000.000/0001-00'

  attr_reader :pdf, :portfolio, :reference_date, :data

  # ============================================================
  def initialize(portfolio, reference_date = Date.current.end_of_month)
    @portfolio      = portfolio
    @reference_date = reference_date

    # !! IMPORTANT: @performance_data MUST be collected before @data
    # so that calculate_index_groups / calculate_asset_type_groups
    # can reference it without going through @data (not yet assigned).
    @performance_data = collect_performance_data
    @data             = collect_data

    @pdf = Prawn::Document.new(
      page_size:   'A4',
      page_layout: :portrait,
      margin:      [MARGIN_T, MARGIN_LR, MARGIN_B, MARGIN_LR]
    )

    configure_fonts
  end

  # ============================================================
  def generate
    render_cover_page
    render_summary_page
    render_fund_details_page
    render_monthly_history_page
    render_fund_distribution_page
    render_analytical_charts_page
    render_asset_type_page
    render_institution_index_page
    render_index_earnings_page
    render_historical_table_page
    render_accumulated_indices_page

    stamp_global_footer
    stamp_page_numbers

    pdf.render
  end

  # ============================================================
  private
  # ============================================================

  def configure_fonts
    base = Rails.root.join('app/assets/fonts')
    pdf.font_families.update(
      'JetBrains Mono' => {
        normal: "#{base}/JetBrainsMono-Regular.ttf",
        bold:   "#{base}/JetBrainsMono-Bold.ttf"
      },
      'Plus Jakarta Sans' => {
        normal:  "#{base}/PlusJakartaSans-Regular.ttf",
        bold:    "#{base}/PlusJakartaSans-Bold.ttf",
        italic:  "#{base}/PlusJakartaSans-Italic.ttf"
      }
    )
    pdf.font 'Plus Jakarta Sans'
  end

  # ============================================================
  #  DATA COLLECTION
  # ============================================================

  # NOTE: collect_performance_data is called in initialize BEFORE collect_data,
  # storing the result in @performance_data. The methods calculate_index_groups
  # and calculate_asset_type_groups reference @performance_data directly.
  def collect_data
    {
      fund_investments:   fund_investments_with_data,
      performance:        @performance_data,
      benchmarks:         collect_benchmark_data,
      monthly_history:    collect_monthly_history,
      monthly_flows:      collect_monthly_flows,
      allocation:         calculate_allocation_data,
      article_groups:     calculate_article_groups,
      index_groups:       calculate_index_groups,
      institution_groups: calculate_institution_groups,
      asset_type_groups:  calculate_asset_type_groups,
      economic_indices:   collect_economic_indices_history
    }
  end

  def fund_investments_with_data
    @portfolio.fund_investments
              .includes(
                :investment_fund,
                investment_fund: { investment_fund_articles: :normative_article }
              )
  end

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

    total_earnings   = performances.sum(:earnings).to_f
    total_initial    = performances.sum(:initial_balance).to_f
    weighted_monthly = BigDecimal('0')
    weighted_yearly  = BigDecimal('0')
    total_alloc      = BigDecimal('0')

    performances.each do |p|
      alloc = p.fund_investment.percentage_allocation.to_d
      total_alloc      += alloc
      weighted_monthly += (p.monthly_return.to_d * alloc)
      weighted_yearly  += (p.yearly_return.to_d  * alloc)
    end

    portfolio_monthly = total_alloc > 0 ? (weighted_monthly / total_alloc).to_f : 0.0
    portfolio_yearly  = total_alloc > 0 ? (weighted_yearly  / total_alloc).to_f : 0.0
    total_value       = @portfolio.fund_investments.sum(:total_invested_value).to_f

    {
      monthly_return:  portfolio_monthly,
      yearly_return:   portfolio_yearly,
      total_earnings:  total_earnings,
      total_value:     total_value,
      initial_balance: total_initial,
      performances:    performances
    }
  end

  def empty_performance
    { monthly_return: 0.0, yearly_return: 0.0, total_earnings: 0.0,
      total_value: 0.0, initial_balance: 0.0, performances: [] }
  end

  def collect_benchmark_data
    indices = EconomicIndex.all.index_by(&:abbreviation)
    result  = {}

    %w[CDI IPCA IMA-GERAL Ibovespa Meta].each do |abbr|
      idx     = indices[abbr]
      monthly = 0.0
      ytd     = 0.0

      if idx
        monthly_rec = idx.economic_index_histories
                         .where(date: @reference_date.beginning_of_month..@reference_date)
                         .order(date: :desc).first
        monthly = monthly_rec&.value.to_f

        ytd = idx.economic_index_histories
                 .where(date: @reference_date.beginning_of_year..@reference_date)
                 .sum(:value).to_f
      end

      key        = abbr.downcase.tr('-', '_').gsub(/\s+/, '_').to_sym
      result[key] = { monthly: monthly, ytd: ytd }
    end

    %i[cdi ipca ima_geral ibovespa meta].each { |k| result[k] ||= { monthly: 0.0, ytd: 0.0 } }
    result
  rescue StandardError => e
    Rails.logger.error("Error collecting benchmark data: #{e.message}")
    # Return zeros for all benchmarks if collection fails
    {
      cdi:        { monthly: 0.0, ytd: 0.0 },
      ipca:       { monthly: 0.0, ytd: 0.0 },
      ima_geral:  { monthly: 0.0, ytd: 0.0 },
      ibovespa:   { monthly: 0.0, ytd: 0.0 },
      meta:       { monthly: 0.0, ytd: 0.0 }
    }
  end

  def collect_monthly_history
    start_date = (@reference_date - 11.months).beginning_of_month

    @portfolio.performance_histories
              .where(period: start_date..@reference_date)
              .group(:period)
              .select('period, SUM(earnings) as total_earnings, SUM(initial_balance) as total_initial')
              .order(period: :asc)
              .map { |r| { period: r.period, earnings: r.total_earnings.to_f, balance: r.total_initial.to_f } }
  end

  def collect_monthly_flows
    start_date = (@reference_date - 11.months).beginning_of_month
    result     = []

    12.times do |i|
      month_start = (start_date + i.months).beginning_of_month
      month_end   = month_start.end_of_month

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

  def calculate_allocation_data
    @portfolio.fund_investments.includes(:investment_fund).map do |fi|
      {
        fund_name:  fi.investment_fund.fund_name,
        allocation: fi.percentage_allocation.to_f,
        value:      fi.total_invested_value.to_f
      }
    end.sort_by { |a| -a[:allocation] }
  end

  def calculate_article_groups
    groups = Hash.new(0.0)
    @portfolio.fund_investments
              .includes(investment_fund: { investment_fund_articles: :normative_article }).each do |fi|
      articles = fi.investment_fund.investment_fund_articles
      if articles.any?
        articles.each do |ifa|
          label = ifa.normative_article&.article_name || 'N/A'
          groups[label] += fi.percentage_allocation.to_f / articles.size
        end
      else
        groups['N/A'] += fi.percentage_allocation.to_f
      end
    end
    groups
  end

  def calculate_index_groups
    groups     = Hash.new { |h, k| h[k] = { allocation: 0.0, value: 0.0, earnings: 0.0 } }
    # Use @performance_data directly — @data is not yet assigned when this runs
    perf_by_fi = (@performance_data[:performances] || []).index_by(&:fund_investment_id)

    @portfolio.fund_investments.includes(:investment_fund).each do |fi|
      ref_idx = fi.investment_fund.originator_fund.presence || 'N/A'
      groups[ref_idx][:allocation] += fi.percentage_allocation.to_f
      groups[ref_idx][:value]      += fi.total_invested_value.to_f
      groups[ref_idx][:earnings]   += perf_by_fi[fi.id]&.earnings.to_f
    end
    groups
  end

  def calculate_institution_groups
    groups = Hash.new { |h, k| h[k] = { value: 0.0, allocation: 0.0 } }
    @portfolio.fund_investments.includes(:investment_fund).each do |fi|
      inst = fi.investment_fund.administrator_name.presence || 'Outros'
      groups[inst][:value]      += fi.total_invested_value.to_f
      groups[inst][:allocation] += fi.percentage_allocation.to_f
    end
    groups
  end

  def calculate_asset_type_groups
    groups     = Hash.new { |h, k| h[k] = { value: 0.0, earnings: 0.0 } }
    # Use @performance_data directly — @data is not yet assigned when this runs
    perf_by_fi = (@performance_data[:performances] || []).index_by(&:fund_investment_id)

    @portfolio.fund_investments
              .includes(investment_fund: { investment_fund_articles: :normative_article }).each do |fi|
      articles = fi.investment_fund.investment_fund_articles
      label = articles.any? ? (articles.first.normative_article&.article_body.presence || 'Renda Fixa Geral') : 'Renda Fixa Geral'
      groups[label][:value]    += fi.total_invested_value.to_f
      groups[label][:earnings] += perf_by_fi[fi.id]&.earnings.to_f
    end
    groups
  end

  def collect_economic_indices_history
    start_date = (@reference_date - 11.months).beginning_of_month
    result     = {}

    EconomicIndex.all.each do |idx|
      rows = idx.economic_index_histories
                .where(date: start_date..@reference_date)
                .order(:date)
                .group_by { |r| r.date.beginning_of_month }

      result[idx.abbreviation] = rows.transform_values { |recs| recs.sum(&:value).to_f }
    end

    result
  end

  # ============================================================
  #  GLOBAL FOOTER
  # ============================================================
  def stamp_global_footer
    pdf.repeat(:all) do
      footer_y = -MARGIN_B + 10

      pdf.stroke_color C[:border]
      pdf.line_width 0.5
      pdf.stroke_horizontal_line 0, CONTENT_W, at: footer_y + 32

      pdf.font('JetBrains Mono', size: 7) do
        pdf.fill_color C[:gray]
        pdf.draw_text "#{PHONE}  |  #{EMAIL}  |  #{SITE}", at: [0, footer_y + 18]
      end

      pdf.font('JetBrains Mono', size: 6) do
        pdf.fill_color C[:gray_light]
        line = "#{COMPANY}  ·  CNPJ #{CNPJ}  ·  " \
          "Gerado em #{Time.current.strftime('%d/%m/%Y às %H:%M')}  ·  " \
          "Relatório elaborado pelo sistema Meta Investimentos"
        pdf.draw_text line, at: [0, footer_y + 4]
      end
    end
  end

  def stamp_page_numbers
    pdf.repeat(:all) do
      pdf.font('JetBrains Mono', size: 7) do
        pdf.fill_color C[:gray_light]
        pdf.number_pages '<page> / <total>',
                         at: [CONTENT_W - 40, -MARGIN_B + 24],
                         align: :right,
                         color: C[:gray_light]
      end
    end
  end

  # ============================================================
  #  PAGE 1 – COVER
  # ============================================================
  def render_cover_page
    pdf.fill_color C[:primary]
    pdf.fill_rectangle [0, pdf.bounds.top], CONTENT_W, pdf.bounds.height * 0.45

    logo_path = Rails.root.join('app/assets/images/logo.png')
    if File.exist?(logo_path)
      pdf.image logo_path.to_s, at: [(CONTENT_W - 120) / 2, pdf.bounds.top - 30], width: 120
    end

    pdf.font('Plus Jakarta Sans', style: :bold, size: 13) do
      pdf.fill_color C[:accent]
      pdf.text_box 'META INVESTIMENTOS', at: [0, pdf.bounds.top - 155], width: CONTENT_W, align: :center
    end

    pdf.font('Plus Jakarta Sans', style: :bold, size: 26) do
      pdf.fill_color C[:white]
      pdf.text_box 'Relatório Mensal', at: [0, pdf.bounds.top - 180], width: CONTENT_W, align: :center
    end

    pdf.font('Plus Jakarta Sans', size: 14) do
      pdf.fill_color 'c7d2fe'
      pdf.text_box format_date_full(@reference_date), at: [0, pdf.bounds.top - 215], width: CONTENT_W, align: :center
    end

    pdf.font('Plus Jakarta Sans', style: :bold, size: 20) do
      pdf.fill_color C[:primary]
      pdf.text_box @portfolio.name, at: [0, pdf.bounds.top - 310], width: CONTENT_W, align: :center
    end

    pdf.stroke_color C[:secondary]
    pdf.line_width 2
    mid = (CONTENT_W - 200) / 2
    pdf.stroke_horizontal_line mid, mid + 200, at: pdf.bounds.top - 340

    pdf.font('Plus Jakarta Sans', size: 11) do
      pdf.fill_color C[:gray]
      pdf.text_box 'Investimentos Institucionais', at: [0, pdf.bounds.top - 360], width: CONTENT_W, align: :center
    end

    draw_cover_metrics
  end

  def draw_cover_metrics
    perf = data[:performance]
    metrics = [
      { label: 'Rentabilidade do Mês', value: fmt_pct(perf[:monthly_return]), color: C[:success] },
      { label: 'Rentabilidade do Ano',  value: fmt_pct(perf[:yearly_return]),  color: C[:primary] },
      { label: 'Ganhos do Mês',         value: fmt_cur(perf[:total_earnings]), color: C[:secondary] },
      { label: 'Patrimônio Total',       value: fmt_cur(perf[:total_value]),    color: C[:primary] }
    ]

    card_w = (CONTENT_W - 15) / 2.0
    card_h = 72
    top_y  = pdf.bounds.top - 420

    metrics.each_with_index do |m, i|
      x = (i % 2) * (card_w + 15)
      y = top_y - (i / 2) * (card_h + 10)

      pdf.fill_color C[:bg_light]
      pdf.fill { pdf.rounded_rectangle [x, y], card_w, card_h, 6 }

      pdf.fill_color m[:color]
      pdf.fill_rectangle [x, y], 4, card_h

      pdf.fill_color C[:gray]
      pdf.font('Plus Jakarta Sans', size: 9) { pdf.text_box m[:label], at: [x + 12, y - 12], width: card_w - 16 }

      pdf.fill_color m[:color]
      pdf.font('Plus Jakarta Sans', style: :bold, size: 17) { pdf.text_box m[:value], at: [x + 12, y - 34], width: card_w - 16 }
    end
  end

  def render_summary_page
    pdf.start_new_page
    page_header('Desempenho da Carteira')

    perf = data[:performance]
    bnch = data[:benchmarks]

    kpis = [
      { label: 'Total da Carteira',   value: fmt_cur(perf[:total_value]),    color: C[:primary] },
      { label: 'Ganhos do Mês',       value: fmt_cur(perf[:total_earnings]), color: C[:success] },
      { label: 'Ganhos do Ano',       value: fmt_cur(perf[:yearly_return].to_f * perf[:total_value].to_f / 100.0), color: C[:accent] },
      { label: 'Rent. do Mês',        value: fmt_pct(perf[:monthly_return]), color: C[:success] },
      { label: 'Rent. do Ano',        value: fmt_pct(perf[:yearly_return]),  color: C[:primary] }
    ]
    draw_kpi_row(kpis, y: pdf.cursor)
    pdf.move_down 16

    cdi_pct  = bnch[:cdi][:ytd].to_f  > 0 ? (perf[:yearly_return].to_f / bnch[:cdi][:ytd].to_f  * 100).round(2) : 0
    ipca_pct = bnch[:ipca][:ytd].to_f > 0 ? (perf[:yearly_return].to_f / bnch[:ipca][:ytd].to_f * 100).round(2) : 0
    ima_pct  = bnch[:ima_geral][:ytd].to_f > 0 ? (perf[:yearly_return].to_f / bnch[:ima_geral][:ytd].to_f * 100).round(2) : 0

    section_title('Carteira em Relação aos Índices')
    idx_table = [
      ['Índice', 'Mensal', 'Anual', '% da Carteira (Ano)'],
      ['CDI',       fmt_pct(bnch[:cdi][:monthly]),       fmt_pct(bnch[:cdi][:ytd]),       "#{fmt_num(cdi_pct, 2)}%"],
      ['IPCA',      fmt_pct(bnch[:ipca][:monthly]),      fmt_pct(bnch[:ipca][:ytd]),      "#{fmt_num(ipca_pct, 2)}%"],
      ['IMA-GERAL', fmt_pct(bnch[:ima_geral][:monthly]), fmt_pct(bnch[:ima_geral][:ytd]), "#{fmt_num(ima_pct, 2)}%"],
      ['Ibovespa',  fmt_pct(bnch[:ibovespa][:monthly]),  fmt_pct(bnch[:ibovespa][:ytd]),  '-']
    ]
    styled_table(idx_table, col_widths: [140, 100, 100, 160])
    pdf.move_down 18

    section_title('Rentabilidade Carteira vs Meta por Mês')
    monthly_returns = build_monthly_returns_series
    meta_series     = build_meta_series
    draw_line_chart(
      series: [
        { label: 'Carteira', color: C[:primary], points: monthly_returns },
        { label: 'Meta',     color: C[:warning], points: meta_series }
      ],
      height: 100, y: pdf.cursor
    )
    pdf.move_down 115

    section_title('Rendimento Mensal – Últimos 12 Meses')
    draw_bar_chart(
      data:   data[:monthly_history].map { |m| [short_month(m[:period]), m[:earnings]] },
      height: 90, y: pdf.cursor, color: C[:secondary]
    )
    pdf.move_down 105

    section_title('Rentabilidade vs Meta – Mês a Mês')
    eco        = data[:economic_indices]
    perf_table = [['Mês', 'Rent. Carteira', 'Meta', 'CDI', 'IPCA']]
    data[:monthly_history].last(6).each do |m|
      per_key = m[:period].beginning_of_month
      cart    = monthly_returns.find { |p| p[:period] == per_key }
      perf_table << [
        full_month(m[:period]),
        fmt_pct(cart&.dig(:value) || 0),
        fmt_pct(eco['Meta']&.dig(per_key)  || bnch[:meta][:monthly]),
        fmt_pct(eco['CDI']&.dig(per_key)   || bnch[:cdi][:monthly]),
        fmt_pct(eco['IPCA']&.dig(per_key)  || bnch[:ipca][:monthly])
      ]
    end
    styled_table(perf_table, col_widths: [160, 90, 80, 80, 80])
  end

  def render_fund_details_page
    pdf.start_new_page
    page_header('Carteira de Investimentos')
    section_title("Carteira de Investimentos – #{month_year_label}")

    perf_by_fi = (@performance_data[:performances] || []).index_by(&:fund_investment_id)
    fund_rows  = [['Fundo', 'Valor Inicial', 'Rendimento', 'Movimentação', 'Valor Final', 'Rent.']]
    totals     = { initial: 0.0, earnings: 0.0, movement: 0.0, final: 0.0 }

    data[:fund_investments].each do |fi|
      perf  = perf_by_fi[fi.id]
      init  = perf&.initial_balance.to_f
      earn  = perf&.earnings.to_f
      apps  = monthly_apps_for(fi)
      reds  = monthly_reds_for(fi)
      move  = apps - reds
      final = init + earn + move
      rent  = perf&.monthly_return.to_f

      totals[:initial]  += init
      totals[:earnings] += earn
      totals[:movement] += move
      totals[:final]    += final

      fund_rows << [truncate(fi.investment_fund.fund_name, 38), fmt_cur(init), fmt_cur(earn), fmt_cur(move), fmt_cur(final), fmt_pct(rent)]
    end

    fund_rows << ['Total', fmt_cur(totals[:initial]), fmt_cur(totals[:earnings]), fmt_cur(totals[:movement]), fmt_cur(totals[:final]), '']
    styled_table(fund_rows, col_widths: [155, 75, 70, 75, 75, 45], last_row_bold: true)
    pdf.move_down 20

    section_title("Relação dos Fundos e Ativos – #{month_year_label}")
    assets_rows = [['CNPJ do Fundo', 'Fundo', 'Índice de Ref.', 'Enq. 4.963/21', 'Taxa de Adm.']]
    data[:fund_investments].each do |fi|
      fund    = fi.investment_fund
      article = fund.investment_fund_articles.first
      norm    = article&.normative_article
      assets_rows << [fund.cnpj || 'N/A', truncate(fund.fund_name, 35), fund.originator_fund.presence || 'N/A', norm&.article_name || 'N/A', article&.note || '0,20%']
    end
    styled_table(assets_rows, col_widths: [110, 155, 70, 110, 70])
  end

  def render_monthly_history_page
    pdf.start_new_page
    page_header('Histórico Patrimonial Mensal')

    hist = data[:monthly_history]
    section_title('Patrimônio Total por Mês – Últimos 12 Meses')
    draw_bar_chart(data: hist.map { |m| [short_month(m[:period]), m[:balance]] }, height: 90, y: pdf.cursor, color: C[:primary])
    pdf.move_down 105

    pat_rows = [['Mês', 'Patrimônio Total', 'Rendimento Mensal']]
    hist.each { |m| pat_rows << [full_month(m[:period]), fmt_cur(m[:balance]), fmt_cur(m[:earnings])] }
    styled_table(pat_rows, col_widths: [200, 160, 155])
    pdf.move_down 24

    flows = data[:monthly_flows]
    section_title('Movimentações por Mês (Aplicações e Resgates)')
    draw_grouped_bar_chart(
      data:   flows.map { |f| [short_month(f[:period]), f[:applications], f[:redemptions]] },
      labels: ['Aplicações', 'Resgates'],
      colors: [C[:success], C[:danger]],
      height: 90, y: pdf.cursor
    )
    pdf.move_down 105

    flow_rows = [['Mês', 'Aplicações', 'Resgates', 'Movimentação Líquida']]
    flows.each { |f| flow_rows << [full_month(f[:period]), fmt_cur(f[:applications]), fmt_cur(f[:redemptions]), fmt_cur(f[:applications] - f[:redemptions])] }
    styled_table(flow_rows, col_widths: [160, 115, 115, 125])
  end

  def render_fund_distribution_page
    pdf.start_new_page
    page_header('Distribuição da Carteira por Fundos')

    alloc = data[:allocation]
    return if alloc.empty?

    section_title("Distribuição da Carteira por Fundos – #{month_year_label}")
    draw_allocation_bars(alloc, y: pdf.cursor)
  end

  def render_analytical_charts_page
    pdf.start_new_page
    page_header('Análise de Conformidade – Política de Investimentos')

    section_title('Distribuição da Carteira por Tipo de Ativo')
    asset_groups = data[:asset_type_groups]
    total_v = asset_groups.values.sum { |v| v[:value] }
    draw_allocation_bars(
      asset_groups.map { |k, v| { fund_name: k, allocation: total_v > 0 ? (v[:value] / total_v * 100).round(2) : 0, value: v[:value] } },
      y: pdf.cursor
    )
    pdf.move_down 10

    section_title('Distribuição por Artigo Normativo (Carteira Atual)')
    art_groups = data[:article_groups]
    draw_allocation_bars(art_groups.map { |k, v| { fund_name: k, allocation: v, value: 0 } }, y: pdf.cursor)
    pdf.move_down 10

    section_title('Carteira vs Política de Investimentos por Artigo')
    policy_rows = [['Artigo', 'Alocação Atual', 'Alvo', 'Mínimo', 'Máximo', 'Situação']]
    art_groups.each do |art, alloc_pct|
      min_t = 60.0; target = 70.0; max_t = 80.0
      status = alloc_pct < min_t ? 'ABAIXO' : alloc_pct > max_t ? 'ACIMA' : 'OK'
      policy_rows << [art, fmt_pct(alloc_pct), fmt_pct(target), fmt_pct(min_t), fmt_pct(max_t), status]
    end
    styled_table(policy_rows, col_widths: [120, 80, 70, 70, 70, 105])
  end

  def render_asset_type_page
    pdf.start_new_page
    page_header('Patrimônio e Rendimento por Tipo de Ativo – CMN 4.963/21')

    asset_groups = data[:asset_type_groups]

    section_title('Rendimento do Mês por Tipo de Ativo')
    draw_horizontal_bars(data: asset_groups.map { |k, v| { label: k, value: v[:earnings] } }, color: C[:success], y: pdf.cursor)
    pdf.move_down 10
    earn_rows = [['Tipo de Ativo', 'Rendimento do Mês', 'Enquadramento 4.963/21']]
    asset_groups.each { |k, v| earn_rows << [k, fmt_cur(v[:earnings]), 'Art. 7º'] }
    styled_table(earn_rows, col_widths: [200, 160, 155])
    pdf.move_down 20

    section_title('Patrimônio do Mês por Tipo de Ativo')
    draw_horizontal_bars(data: asset_groups.map { |k, v| { label: k, value: v[:value] } }, color: C[:primary], y: pdf.cursor)
    pdf.move_down 10
    pat_rows = [['Tipo de Ativo', 'Patrimônio', 'Enquadramento 4.963/21']]
    asset_groups.each { |k, v| pat_rows << [k, fmt_cur(v[:value]), 'Art. 7º'] }
    styled_table(pat_rows, col_widths: [200, 160, 155])
  end

  # ============================================================
  #  PAGE 8 – INSTITUTION & INDEX
  # ============================================================
  def render_institution_index_page
    pdf.start_new_page
    page_header('Distribuição por Instituição e Índice de Referência')

    inst       = data[:institution_groups]
    total_inst = inst.values.sum { |v| v[:value] }
    section_title('Distribuição dos Investimentos por Instituição Financeira')
    draw_allocation_bars(inst.map { |k, v| { fund_name: k, allocation: total_inst > 0 ? (v[:value] / total_inst * 100).round(2) : 0, value: v[:value] } }, y: pdf.cursor)
    inst_rows = [['Instituição Financeira', 'Patrimônio', '% da Carteira']]
    inst.sort_by { |_, v| -v[:value] }.each { |k, v| inst_rows << [k, fmt_cur(v[:value]), fmt_pct(total_inst > 0 ? (v[:value] / total_inst * 100).round(2) : 0)] }
    styled_table(inst_rows, col_widths: [250, 155, 110])
    pdf.move_down 20

    idx_groups = data[:index_groups]
    total_idx  = idx_groups.values.sum { |v| v[:value] }
    section_title('Patrimônio por Índice de Referência do Mês')
    draw_allocation_bars(idx_groups.map { |k, v| { fund_name: k, allocation: total_idx > 0 ? (v[:value] / total_idx * 100).round(2) : 0, value: v[:value] } }, y: pdf.cursor)
    idx_rows = [['Índice de Referência', 'Patrimônio', '% da Carteira']]
    idx_groups.sort_by { |_, v| -v[:value] }.each { |k, v| idx_rows << [k, fmt_cur(v[:value]), fmt_pct(total_idx > 0 ? (v[:value] / total_idx * 100).round(2) : 0)] }
    styled_table(idx_rows, col_widths: [200, 190, 125])
  end

  # ============================================================
  #  PAGE 9 – INDEX EARNINGS
  # ============================================================
  def render_index_earnings_page
    pdf.start_new_page
    page_header('Rendimento do Mês por Índice de Referência')

    idx_groups  = data[:index_groups]
    total_earn  = idx_groups.values.sum { |v| v[:earnings] }
    section_title("Rendimento por Benchmark – #{month_year_label}")
    draw_horizontal_bars(data: idx_groups.map { |k, v| { label: k, value: v[:earnings] } }, color: C[:secondary], y: pdf.cursor)
    pdf.move_down 14

    earn_rows = [['Índice de Referência', 'Rendimento do Mês', '% do Total']]
    idx_groups.sort_by { |_, v| -v[:earnings] }.each do |k, v|
      pct = total_earn > 0 ? (v[:earnings] / total_earn * 100).round(2) : 0
      earn_rows << [k, fmt_cur(v[:earnings]), fmt_pct(pct)]
    end
    earn_rows << ['Total', fmt_cur(total_earn), '100,00%']
    styled_table(earn_rows, col_widths: [200, 190, 125], last_row_bold: true)
  end

  # ============================================================
  #  PAGE 10 – HISTORICAL TABLE
  # ============================================================
  def render_historical_table_page
    pdf.start_new_page
    page_header('Histórico Mensal e Índices Econômicos')

    hist      = data[:monthly_history]
    hist_rows = [['Mês', 'Patrimônio Total', 'Rendimento Mensal']]
    hist.each { |m| hist_rows << [full_month(m[:period]), fmt_cur(m[:balance]), fmt_cur(m[:earnings])] }
    hist_rows << ['Total', '', fmt_cur(hist.sum { |m| m[:earnings] })]
    section_title('Histórico Mensal')
    styled_table(hist_rows, col_widths: [200, 157, 158], last_row_bold: true)
    pdf.move_down 22

    eco  = data[:economic_indices]
    bnch = data[:benchmarks]
    idx_tbl = [['Mês', 'Meta', 'IPCA', 'CDI', 'IMA-GERAL', 'Ibovespa']]
    hist.each do |m|
      per = m[:period].beginning_of_month
      idx_tbl << [
        full_month(m[:period]),
        fmt_pct(eco['Meta']&.dig(per)      || bnch[:meta][:monthly]),
        fmt_pct(eco['IPCA']&.dig(per)      || bnch[:ipca][:monthly]),
        fmt_pct(eco['CDI']&.dig(per)       || bnch[:cdi][:monthly]),
        fmt_pct(eco['IMA-GERAL']&.dig(per) || bnch[:ima_geral][:monthly]),
        fmt_pct(eco['Ibovespa']&.dig(per)  || bnch[:ibovespa][:monthly])
      ]
    end
    section_title('Índices por Mês')
    styled_table(idx_tbl, col_widths: [140, 75, 75, 75, 85, 65])
  end

  # ============================================================
  #  PAGE 11 – ACCUMULATED INDICES
  # ============================================================
  def render_accumulated_indices_page
    pdf.start_new_page
    page_header('Índices Acumulados no Ano')

    perf  = data[:performance]
    bnch  = data[:benchmarks]

    section_title('Rentabilidade Acumulada – Comparativo com Benchmarks')
    acc_data = [
      { label: 'Carteira',  value: perf[:yearly_return], color: C[:primary] },
      { label: 'Meta',      value: bnch[:meta][:ytd],      color: C[:warning] },
      { label: 'CDI',       value: bnch[:cdi][:ytd],       color: C[:accent] },
      { label: 'IPCA',      value: bnch[:ipca][:ytd],      color: C[:success] },
      { label: 'IMA-GERAL', value: bnch[:ima_geral][:ytd], color: C[:secondary] },
      { label: 'Ibovespa',  value: bnch[:ibovespa][:ytd],  color: C[:danger] }
    ]
    draw_comparison_bars(acc_data, y: pdf.cursor)
    pdf.move_down 14

    cdi_r  = bnch[:cdi][:ytd].to_f  > 0 ? (perf[:yearly_return].to_f / bnch[:cdi][:ytd].to_f  * 100).round(2) : 0
    ipca_r = bnch[:ipca][:ytd].to_f > 0 ? (perf[:yearly_return].to_f / bnch[:ipca][:ytd].to_f * 100).round(2) : 0
    ima_r  = bnch[:ima_geral][:ytd].to_f > 0 ? (perf[:yearly_return].to_f / bnch[:ima_geral][:ytd].to_f * 100).round(2) : 0

    acc_rows = [
      ['Indicador', 'Rent. Acumulada', '% em Relação à Carteira'],
      ['Carteira',   fmt_pct(perf[:yearly_return]),    '100,00%'],
      ['Meta',       fmt_pct(bnch[:meta][:ytd]),       '-'],
      ['CDI',        fmt_pct(bnch[:cdi][:ytd]),        "#{fmt_num(cdi_r, 2)}%"],
      ['IPCA',       fmt_pct(bnch[:ipca][:ytd]),       "#{fmt_num(ipca_r, 2)}%"],
      ['IMA-GERAL',  fmt_pct(bnch[:ima_geral][:ytd]),  "#{fmt_num(ima_r, 2)}%"],
      ['Ibovespa',   fmt_pct(bnch[:ibovespa][:ytd]),   '-']
    ]
    styled_table(acc_rows, col_widths: [160, 170, 185])
  end

  # ============================================================
  #  CHART HELPERS
  # ============================================================
  def draw_bar_chart(data:, height:, y:, color: C[:primary])
    if data.empty?
      pdf.fill_color C[:gray]
      pdf.font('Plus Jakarta Sans', size: 9, style: :italic) do
        pdf.text_box 'Dados não disponíveis para o período', at: [0, y - 20], width: CONTENT_W, align: :center
      end
      return
    end

    values  = data.map { |_, v| v.to_f }
    max_val = values.max.nonzero? || 1.0
    bar_w   = (CONTENT_W - 40) / [data.size, 1].max.to_f
    chart_y = y - 8

    pdf.stroke_color C[:border]
    pdf.line_width 0.5
    pdf.stroke_horizontal_line 0, CONTENT_W, at: chart_y - height

    data.each_with_index do |(label, val), i|
      val  = val.to_f
      bh   = (val.abs / max_val * (height - 10)).round(1)
      x    = i * bar_w + bar_w * 0.15
      w    = bar_w * 0.7
      by   = chart_y - height

      pdf.fill_color val >= 0 ? color : C[:danger]
      pdf.fill_rectangle [x, by + bh], w, bh

      pdf.fill_color C[:gray_light]
      pdf.font('JetBrains Mono', size: 5.5) { pdf.draw_text label.to_s[0..4], at: [x, by - 9] }
    end
  rescue StandardError => e
    Rails.logger.error("Error drawing bar chart: #{e.message}")
    pdf.fill_color C[:gray]
    pdf.font('Plus Jakarta Sans', size: 9, style: :italic) do
      pdf.text_box 'Erro ao renderizar gráfico', at: [0, y - 20], width: CONTENT_W, align: :center
    end
  end

  def draw_grouped_bar_chart(data:, labels:, colors:, height:, y:)
    if data.empty?
      pdf.fill_color C[:gray]
      pdf.font('Plus Jakarta Sans', size: 9, style: :italic) do
        pdf.text_box 'Dados não disponíveis para o período', at: [0, y - 20], width: CONTENT_W, align: :center
      end
      return
    end

    values  = data.flat_map { |_, a, b| [a, b] }.map(&:to_f)
    max_val = values.max.nonzero? || 1.0
    group_w = (CONTENT_W - 20) / [data.size, 1].max.to_f
    chart_y = y - 8

    pdf.stroke_color C[:border]
    pdf.line_width 0.5
    pdf.stroke_horizontal_line 0, CONTENT_W, at: chart_y - height

    data.each_with_index do |(label, v1, v2), i|
      x    = i * group_w + 4
      bw   = (group_w - 8) / 2.0
      base = chart_y - height

      [v1, v2].each_with_index do |val, j|
        bh = (val.to_f.abs / max_val * (height - 10)).round(1)
        pdf.fill_color colors[j]
        pdf.fill_rectangle [x + j * bw, base + bh], bw * 0.9, bh
      end

      pdf.fill_color C[:gray_light]
      pdf.font('JetBrains Mono', size: 5.5) { pdf.draw_text label.to_s[0..4], at: [x, base - 9] }
    end

    labels.each_with_index do |lbl, i|
      lx = CONTENT_W - 160 + i * 80
      ly = chart_y + 2
      pdf.fill_color colors[i]
      pdf.fill_rectangle [lx, ly + 7], 10, 7
      pdf.fill_color C[:gray]
      pdf.font('Plus Jakarta Sans', size: 7) { pdf.draw_text lbl, at: [lx + 13, ly] }
    end
  rescue StandardError => e
    Rails.logger.error("Error drawing grouped bar chart: #{e.message}")
    pdf.fill_color C[:gray]
    pdf.font('Plus Jakarta Sans', size: 9, style: :italic) do
      pdf.text_box 'Erro ao renderizar gráfico', at: [0, y - 20], width: CONTENT_W, align: :center
    end
  end

  def draw_line_chart(series:, height:, y:)
    all_vals = series.flat_map { |s| s[:points].map { |p| p[:value].to_f } }

    if all_vals.empty? || series.first[:points].empty?
      pdf.fill_color C[:gray]
      pdf.font('Plus Jakarta Sans', size: 9, style: :italic) do
        pdf.text_box 'Dados não disponíveis para o período', at: [0, y - 20], width: CONTENT_W, align: :center
      end
      return
    end

    min_val  = [all_vals.min.to_f, 0.0].min
    max_val  = all_vals.max.to_f
    range    = (max_val - min_val).nonzero? || 1.0
    chart_y  = y - 8
    n_points = series.first[:points].size

    pdf.stroke_color C[:border]
    pdf.line_width 0.4
    pdf.stroke_horizontal_line 0, CONTENT_W, at: chart_y - height
    pdf.stroke_vertical_line chart_y - height, chart_y, at: 0

    series.each do |s|
      pts = s[:points]
      next if pts.size < 2

      pdf.stroke_color s[:color]
      pdf.line_width 1.2
      pdf.stroke do
        (pts.size - 1).times do |i|
          x1 = i.to_f / (n_points - 1) * CONTENT_W
          y1 = chart_y - height + ((pts[i][:value].to_f - min_val) / range * (height - 12))
          x2 = (i + 1).to_f / (n_points - 1) * CONTENT_W
          y2 = chart_y - height + ((pts[i + 1][:value].to_f - min_val) / range * (height - 12))
          pdf.line [x1, y1], [x2, y2]
        end
      end
    end

    pts_for_labels = series.first[:points]
    pts_for_labels.each_with_index do |pt, i|
      x = i.to_f / (n_points - 1) * CONTENT_W
      pdf.fill_color C[:gray_light]
      pdf.font('JetBrains Mono', size: 5) { pdf.draw_text pt[:label].to_s[0..2], at: [x - 6, chart_y - height - 9] }
    end

    series.each_with_index do |s, i|
      lx = i * 80
      pdf.fill_color s[:color]
      pdf.fill_rectangle [lx, chart_y + 10], 12, 4
      pdf.fill_color C[:gray]
      pdf.font('Plus Jakarta Sans', size: 7) { pdf.draw_text s[:label], at: [lx + 16, chart_y + 4] }
    end
  rescue StandardError => e
    Rails.logger.error("Error drawing line chart: #{e.message}")
    pdf.fill_color C[:gray]
    pdf.font('Plus Jakarta Sans', size: 9, style: :italic) do
      pdf.text_box 'Erro ao renderizar gráfico', at: [0, y - 20], width: CONTENT_W, align: :center
    end
  end

  def draw_allocation_bars(alloc, y:)
    if alloc.empty?
      pdf.fill_color C[:gray]
      pdf.font('Plus Jakarta Sans', size: 9, style: :italic) do
        pdf.text_box 'Não há dados de alocação disponíveis', at: [0, y - 20], width: CONTENT_W, align: :center
      end
      pdf.move_down 40
      return
    end

    bar_h     = 14
    spacing   = 20
    max_alloc = alloc.map { |a| a[:allocation].to_f }.max.nonzero? || 1.0

    alloc.first(12).each_with_index do |item, i|
      by      = y - i * spacing - 6
      alloc_f = item[:allocation].to_f
      bar_w   = (alloc_f / max_alloc * (CONTENT_W - 160)).round(1)
      color   = C[:chart][i % C[:chart].size]

      pdf.fill_color C[:gray_dark]
      pdf.font('Plus Jakarta Sans', size: 7) { pdf.draw_text truncate(item[:fund_name].to_s, 28), at: [0, by] }

      pdf.fill_color color
      pdf.fill_rectangle [160, by + bar_h - 2], [bar_w, 1].max, bar_h - 4

      pdf.fill_color C[:gray]
      pdf.font('JetBrains Mono', size: 7) { pdf.draw_text "#{fmt_num(alloc_f, 2)}%", at: [164 + bar_w + 4, by] }

      break if by < 20
    end

    pdf.move_down [alloc.size, 12].min * spacing + 10
  rescue StandardError => e
    Rails.logger.error("Error drawing allocation bars: #{e.message}")
    pdf.fill_color C[:gray]
    pdf.font('Plus Jakarta Sans', size: 9, style: :italic) { pdf.text 'Erro ao renderizar alocação' }
    pdf.move_down 40
  end

  def draw_horizontal_bars(data:, color:, y:)
    if data.empty?
      pdf.fill_color C[:gray]
      pdf.font('Plus Jakarta Sans', size: 9, style: :italic) do
        pdf.text_box 'Dados não disponíveis', at: [0, y - 20], width: CONTENT_W, align: :center
      end
      pdf.move_down 40
      return
    end

    bar_h   = 14
    spacing = 22
    max_val = data.map { |d| d[:value].to_f }.max.nonzero? || 1.0

    data.first(8).each_with_index do |item, i|
      by    = y - i * spacing - 6
      bar_w = (item[:value].to_f / max_val * (CONTENT_W - 200)).round(1)

      pdf.fill_color C[:gray_dark]
      pdf.font('Plus Jakarta Sans', size: 7) { pdf.draw_text truncate(item[:label].to_s, 26), at: [0, by] }

      pdf.fill_color color
      pdf.fill_rectangle [170, by + bar_h - 2], [bar_w, 1].max, bar_h - 4

      pdf.fill_color C[:gray]
      pdf.font('JetBrains Mono', size: 7) { pdf.draw_text fmt_cur(item[:value]), at: [174 + bar_w + 4, by] }

      break if by < 20
    end

    pdf.move_down [data.size, 8].min * spacing + 10
  rescue StandardError => e
    Rails.logger.error("Error drawing horizontal bars: #{e.message}")
    pdf.fill_color C[:gray]
    pdf.font('Plus Jakarta Sans', size: 9, style: :italic) { pdf.text 'Erro ao renderizar gráfico' }
    pdf.move_down 40
  end

  def draw_comparison_bars(items, y:)
    bar_h   = 18
    spacing = 26
    max_val = items.map { |i| i[:value].to_f }.max.nonzero? || 1.0

    items.each_with_index do |item, i|
      by    = y - i * spacing - 6
      bar_w = (item[:value].to_f.abs / max_val * (CONTENT_W - 140)).round(1)

      pdf.fill_color C[:gray_dark]
      pdf.font('Plus Jakarta Sans', size: 8) { pdf.draw_text item[:label].to_s, at: [0, by] }

      pdf.fill_color item[:color]
      pdf.fill_rectangle [80, by + bar_h - 2], [bar_w, 1].max, bar_h - 4

      pdf.fill_color C[:gray_dark]
      pdf.font('JetBrains Mono', style: :bold, size: 8) { pdf.draw_text fmt_pct(item[:value]), at: [84 + bar_w + 6, by] }
    end

    pdf.move_down items.size * spacing + 10
  end

  # ============================================================
  #  TABLE HELPER
  # ============================================================
  def styled_table(rows, col_widths: nil, last_row_bold: false)
    return if rows.size < 2

    # Sanitize all cell content to prevent encoding issues
    sanitized_rows = rows.map do |row|
      row.map { |cell| cell.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?') }
    end

    opts = {
      header:     true,
      width:      CONTENT_W,
      cell_style: {
        font:          'Plus Jakarta Sans',
        size:          7.5,
        padding:       [4, 5],
        borders:       [:bottom],
        border_color:  C[:border],
        border_width:  0.4,
        inline_format: true,
        overflow:      :shrink_to_fit,
        min_font_size: 6
      }
    }
    opts[:column_widths] = col_widths if col_widths

    pdf.table(sanitized_rows, opts) do |t|
      t.row(0).font_style       = :bold
      t.row(0).text_color       = C[:white]
      t.row(0).background_color = C[:primary]
      t.row(0).borders          = []

      t.rows(1..-1).text_color       = C[:gray_dark]
      t.rows(1..-1).background_color = C[:white]

      t.rows(1..-1).each_with_index do |row, idx|
        row.background_color = idx.even? ? C[:bg_light] : C[:white]
      end

      if last_row_bold && sanitized_rows.size > 1
        t.row(-1).font_style       = :bold
        t.row(-1).text_color       = C[:primary]
        t.row(-1).background_color = C[:bg_blue]
      end
    end
  rescue Prawn::Errors::CannotFit => e
    # Fallback: render without column widths
    begin
      pdf.table(sanitized_rows, opts.except(:column_widths)) do |t|
        t.row(0).font_style       = :bold
        t.row(0).background_color = C[:primary]
        t.row(0).text_color       = C[:white]
      end
    rescue StandardError
      # Last resort: simple text output
      pdf.font('Plus Jakarta Sans', size: 7) do
        sanitized_rows.each { |row| pdf.text row.join(' | ') }
      end
    end
  end

  # ============================================================
  #  PAGE LAYOUT HELPERS
  # ============================================================
  def page_header(title)
    pdf.fill_color C[:primary]
    pdf.fill_rectangle [0, pdf.bounds.top], CONTENT_W, 36

    pdf.fill_color C[:white]
    pdf.font('Plus Jakarta Sans', style: :bold, size: 13) do
      pdf.text_box title, at: [10, pdf.bounds.top - 8], width: CONTENT_W - 140
    end

    pdf.font('JetBrains Mono', size: 7.5) do
      pdf.fill_color 'c7d2fe'
      date_str = "Relatório: #{month_year_label}"
      tw = pdf.width_of(date_str, font: 'JetBrains Mono', size: 7.5)
      pdf.draw_text date_str, at: [CONTENT_W - tw - 6, pdf.bounds.top - 14]
    end

    pdf.move_down 46
  end

  def section_title(text)
    pdf.fill_color C[:primary]
    pdf.font('Plus Jakarta Sans', style: :bold, size: 9.5) { pdf.text text.upcase }
    pdf.fill_color C[:accent]
    pdf.stroke_color C[:accent]
    pdf.line_width 1
    pdf.stroke_horizontal_line 0, 60, at: pdf.cursor
    pdf.move_down 8
  end

  def draw_kpi_row(kpis, y:)
    card_w = (CONTENT_W - (kpis.size - 1) * 8.0) / kpis.size
    card_h = 52

    kpis.each_with_index do |kpi, i|
      x = i * (card_w + 8)

      pdf.fill_color C[:bg_light]
      pdf.fill { pdf.rounded_rectangle [x, y], card_w, card_h, 5 }

      pdf.fill_color kpi[:color]
      pdf.fill_rectangle [x, y], 3, card_h

      pdf.fill_color C[:gray]
      pdf.font('Plus Jakarta Sans', size: 7) { pdf.text_box kpi[:label], at: [x + 7, y - 8], width: card_w - 10 }

      pdf.fill_color kpi[:color]
      pdf.font('Plus Jakarta Sans', style: :bold, size: 11) { pdf.text_box kpi[:value], at: [x + 7, y - 24], width: card_w - 10 }
    end

    pdf.move_down card_h + 8
  end

  # ============================================================
  #  SERIES BUILDERS
  # ============================================================
  def build_monthly_returns_series
    data[:monthly_history].map do |m|
      perfs = @portfolio.performance_histories
                        .where(period: m[:period])
                        .includes(fund_investment: :investment_fund)

      alloc_total = perfs.sum { |p| p.fund_investment.percentage_allocation.to_f }
      weighted    = perfs.sum { |p| p.monthly_return.to_f * p.fund_investment.percentage_allocation.to_f }
      ret         = alloc_total > 0 ? (weighted / alloc_total) : 0.0

      { period: m[:period].beginning_of_month, value: ret, label: short_month(m[:period]) }
    end
  end

  def build_meta_series
    eco  = data[:economic_indices]
    bnch = data[:benchmarks]
    data[:monthly_history].map do |m|
      per = m[:period].beginning_of_month
      val = eco['Meta']&.dig(per) || bnch[:meta][:monthly]
      { period: per, value: val.to_f, label: short_month(m[:period]) }
    end
  end

  # ============================================================
  #  FLOW HELPERS
  # ============================================================
  def monthly_apps_for(fi)
    fi.applications
      .where(cotization_date: @reference_date.beginning_of_month..@reference_date)
      .sum(:financial_value).to_f
  rescue StandardError
    0.0
  end

  def monthly_reds_for(fi)
    fi.redemptions
      .where(cotization_date: @reference_date.beginning_of_month..@reference_date)
      .sum(:redeemed_liquid_value).to_f
  rescue StandardError
    0.0
  end

  # ============================================================
  #  FORMATTERS
  # ============================================================
  def fmt_cur(value)
    ActionController::Base.helpers.number_to_currency(
      value.to_f, unit: 'R$ ', separator: ',', delimiter: '.', precision: 2
    )
  end

  def fmt_pct(value)
    "#{fmt_num(value.to_f, 2)}%"
  end

  def fmt_num(value, decimals = 0)
    ActionController::Base.helpers.number_with_precision(
      value.to_f, precision: decimals, separator: ',', delimiter: '.'
    )
  end

  def truncate(text, len)
    text.to_s.length > len ? "#{text[0...len]}…" : text.to_s
  end

  def format_date_full(date)
    day   = date.day
    month = I18n.l(date, format: '%B')
    year  = date.year
    "#{day} de #{month} de #{year}"
  end

  def short_month(date)
    I18n.l(date.to_date, format: '%b').capitalize
  rescue StandardError
    date.strftime('%b')
  end

  def full_month(date)
    I18n.l(date.to_date, format: '%B de %Y').capitalize
  rescue StandardError
    date.strftime('%B de %Y')
  end

  def month_year_label
    I18n.l(@reference_date, format: '%B %Y').capitalize
  rescue StandardError
    @reference_date.strftime('%B %Y')
  end
end