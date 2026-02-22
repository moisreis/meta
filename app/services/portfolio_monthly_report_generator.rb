class PortfolioMonthlyReportGenerator
  require 'prawn'
  require 'prawn/table'
  require 'bigdecimal'

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
    chart: %w[8fe3d6 56d279 fb6e76 7eb7dc 34cfdc 7a7be0
                     7c86ff a3e500 00d5be d8db00 b09bea 73b1e7]
  }.freeze

  PAGE_W = 595.28
  PAGE_H = 841.89
  MARGIN_T = 40
  MARGIN_B = 70
  MARGIN_LR = 40
  CONTENT_W = PAGE_W - MARGIN_LR * 2

  PHONE = '(74) 981-399-579'
  EMAIL = 'mr.investing@outlook.com'
  SITE = 'www.investingmeta.com.br'
  COMPANY = 'META CONSULTORIA DE INVESTIMENTOS INSTITUCIONAIS'
  CNPJ = '34.369.665/0001-99'

  attr_reader :pdf, :portfolio, :reference_date, :data

  def initialize(portfolio, reference_date = Date.current.end_of_month)
    @portfolio = portfolio
    @reference_date = reference_date
    @performance_data = collect_performance_data
    @data = collect_data
    @pdf = Prawn::Document.new(
      page_size: 'A4',
      page_layout: :portrait,
      margin: [MARGIN_T, MARGIN_LR, MARGIN_B, MARGIN_LR]
    )
    configure_fonts
  end

  def generate
    render_cover_page
    render_summary_page
    render_fund_details_page
    render_monthly_history_page
    render_fund_distribution_page
    render_index_earnings_page
    render_historical_table_page
    render_accumulated_indices_page
    stamp_global_footer
    pdf.render
  end

  private

  def configure_fonts
    pdf.font_families.update(
      "Source Serif 4" => {
        normal: Rails.root.join("app/assets/fonts/SourceSerif4-Regular.ttf"),
        bold: Rails.root.join("app/assets/fonts/SourceSerif4-Bold.ttf"),
        italic: Rails.root.join("app/assets/fonts/SourceSerif4-Italic.ttf")
      },
      "JetBrains Mono" => {
        normal: Rails.root.join("app/assets/fonts/JetBrainsMono-Regular.ttf"),
        bold: Rails.root.join("app/assets/fonts/JetBrainsMono-Bold.ttf")
      },
      "Plus Jakarta Sans" => {
        normal: Rails.root.join("app/assets/fonts/PlusJakartaSans-Regular.ttf"),
        bold: Rails.root.join("app/assets/fonts/PlusJakartaSans-Bold.ttf"),
        italic: Rails.root.join("app/assets/fonts/PlusJakartaSans-Italic.ttf")
      },
      "IBM Plex Mono" => {
        normal: Rails.root.join("app/assets/fonts/IBMPlexMono-Regular.ttf"),
        bold: Rails.root.join("app/assets/fonts/IBMPlexMono-Bold.ttf"),
        italic: Rails.root.join("app/assets/fonts/IBMPlexMono-Italic.ttf")
      },
      "Geist Pixel Square" => {
        normal: Rails.root.join("app/assets/fonts/GeistPixel-Square.ttf"),
      }
    )
    pdf.font 'Plus Jakarta Sans'
  end

  def collect_data
    {
      fund_investments: fund_investments_with_data,
      performance: @performance_data,
      benchmarks: collect_benchmark_data,
      monthly_history: collect_monthly_history,
      monthly_flows: collect_monthly_flows,
      allocation: calculate_allocation_data,
      article_groups: calculate_article_groups,
      index_groups: calculate_index_groups,
      institution_groups: calculate_institution_groups,
      asset_type_groups: calculate_asset_type_groups,
      economic_indices: collect_economic_indices_history
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

    total_earnings = @portfolio.total_gain.to_f
    total_initial  = performances.sum(:initial_balance).to_f

    weighted_monthly = BigDecimal('0')
    total_alloc      = BigDecimal('0')

    performances.each do |p|
      alloc = p.fund_investment.percentage_allocation.to_d
      total_alloc      += alloc
      weighted_monthly += (p.monthly_return.to_d * alloc)
    end

    portfolio_monthly = total_alloc > 0 ? (weighted_monthly / total_alloc).to_f : 0.0

    # Yearly: acumula monthly_return de todos os snapshots do ano por fundo
    by_fi = @portfolio.performance_histories
                      .where(period: @reference_date.beginning_of_year..@reference_date)
                      .includes(:fund_investment)
                      .group_by(&:fund_investment_id)

    weighted_yearly  = BigDecimal('0')
    total_alloc_year = BigDecimal('0')

    by_fi.each do |_, fund_perfs|
      fi    = fund_perfs.first.fund_investment
      alloc = fi.percentage_allocation.to_d
      accumulated      = fund_perfs.sum { |p| p.monthly_return.to_d }
      weighted_yearly  += accumulated * alloc
      total_alloc_year += alloc
    end

    portfolio_yearly = total_alloc_year > 0 ? (weighted_yearly / total_alloc_year).to_f : 0.0
    total_value      = @portfolio.total_current_market_value.to_f

    {
      monthly_return: portfolio_monthly,
      yearly_return:  portfolio_yearly,
      total_earnings: total_earnings,
      total_value:    total_value,
      initial_balance: total_initial,
      performances:   performances
    }
  end

  def empty_performance
    { monthly_return: 0.0, yearly_return: 0.0, total_earnings: 0.0,
      total_value: 0.0, initial_balance: 0.0, performances: [] }
  end

  def collect_benchmark_data
    indices = EconomicIndex.all.index_by(&:abbreviation)
    result = {}

    %w[CDI IPCA IMA-GERAL Ibovespa Meta].each do |abbr|
      idx = indices[abbr]
      monthly = 0.0
      ytd = 0.0

      if idx
        monthly_rec = idx.economic_index_histories
                         .where(date: @reference_date.beginning_of_month..@reference_date)
                         .order(date: :desc).first
        monthly = monthly_rec&.value.to_f

        ytd = idx.economic_index_histories
                 .where(date: @reference_date.beginning_of_year..@reference_date)
                 .sum(:value).to_f
      end

      key = abbr.downcase.tr('-', '_').gsub(/\s+/, '_').to_sym
      result[key] = { monthly: monthly, ytd: ytd }
    end

    %i[cdi ipca ima_geral ibovespa meta].each { |k| result[k] ||= { monthly: 0.0, ytd: 0.0 } }
    result
  rescue StandardError => e
    Rails.logger.error("Error collecting benchmark data: #{e.message}")
    {
      cdi: { monthly: 0.0, ytd: 0.0 },
      ipca: { monthly: 0.0, ytd: 0.0 },
      ima_geral: { monthly: 0.0, ytd: 0.0 },
      ibovespa: { monthly: 0.0, ytd: 0.0 },
      meta: { monthly: 0.0, ytd: 0.0 }
    }
  end

  def collect_monthly_history
    start_date = (@reference_date - 11.months).beginning_of_month

    rows = @portfolio.performance_histories
                     .where(period: start_date..@reference_date)
                     .group(:period)
                     .select('period, SUM(earnings) as total_earnings, SUM(initial_balance) as total_initial')
                     .order(period: :asc)
                     .map do |r|
      balance  = r.total_initial.to_f + r.total_earnings.to_f
      earnings = r.total_earnings.to_f
      { period: r.period, earnings: earnings, balance: balance }
    end

    # Sobrescreve o mês de referência com os valores corretos do portfolio
    if rows.any? && rows.last[:period] == @reference_date
      rows.last[:earnings] = @portfolio.total_gain.to_f
      rows.last[:balance]  = @portfolio.total_current_market_value.to_f
    end

    rows
  end

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

  def calculate_allocation_data
    @portfolio.fund_investments.includes(:investment_fund).map do |fi|
      {
        fund_name: fi.investment_fund.fund_name,
        allocation: fi.percentage_allocation.to_f,
        value: fi.total_invested_value.to_f
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
          label = ifa.normative_article&.article_name || '-'
          groups[label] += fi.percentage_allocation.to_f / articles.size
        end
      else
        groups['-'] += fi.percentage_allocation.to_f
      end
    end
    groups
  end

  def calculate_index_groups
    groups = Hash.new { |h, k| h[k] = { allocation: 0.0, value: 0.0, earnings: 0.0 } }

    @portfolio.fund_investments.includes(:investment_fund).each do |fi|
      ref_idx = fi.investment_fund.originator_fund.presence || '-'
      groups[ref_idx][:allocation] += fi.percentage_allocation.to_f
      groups[ref_idx][:value]      += fi.total_invested_value.to_f
      groups[ref_idx][:earnings]   += fi.total_gain.to_f
    end

    groups
  end

  def calculate_institution_groups
    groups = Hash.new { |h, k| h[k] = { value: 0.0, allocation: 0.0 } }
    @portfolio.fund_investments.includes(:investment_fund).each do |fi|
      inst = fi.investment_fund.administrator_name.presence || 'Outros'
      groups[inst][:value] += fi.total_invested_value.to_f
      groups[inst][:allocation] += fi.percentage_allocation.to_f
    end
    groups
  end

  def calculate_asset_type_groups
    groups = Hash.new { |h, k| h[k] = { value: 0.0, earnings: 0.0 } }
    perf_by_fi = (@performance_data[:performances] || []).index_by(&:fund_investment_id)

    @portfolio.fund_investments
              .includes(investment_fund: { investment_fund_articles: :normative_article }).each do |fi|
      articles = fi.investment_fund.investment_fund_articles
      label = articles.any? ? (articles.first.normative_article&.article_body.presence || 'Renda Fixa Geral') : 'Renda Fixa Geral'
      groups[label][:value] += fi.total_invested_value.to_f
      groups[label][:earnings] += perf_by_fi[fi.id]&.earnings.to_f
    end
    groups
  end

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

  def stamp_global_footer
    pdf.repeat(:all) do
      footer_y = -MARGIN_B + 10

      pdf.font('Geist Pixel Square', size: 6) do
        pdf.fill_color C[:gray_light]

        page_text = "#{pdf.page_number} de #{pdf.page_count}"
        text_width = pdf.width_of(page_text)

        pdf.draw_text(
          page_text,
          at: [CONTENT_W - text_width, footer_y + 4]
        )
      end
    end
  end

  def render_cover_page
    pdf.fill_color C[:bg_light]
    pdf.fill_rectangle [-MARGIN_LR, pdf.bounds.top + MARGIN_T], PAGE_W, PAGE_H

    pdf.font('Geist Pixel Square', size: 9) do
      pdf.fill_color C[:body]
      pdf.text_box format_date_full(@reference_date).upcase,
                   at: [0, pdf.bounds.top - 20],
                   width: CONTENT_W / 2,
                   align: :left

      pdf.text_box 'META INVESTIMENTOS',
                   at: [CONTENT_W / 2, pdf.bounds.top - 20],
                   width: CONTENT_W / 2,
                   align: :right
    end

    pdf.font('Source Serif 4', size: 36) do
      pdf.fill_color C[:body]
      pdf.text_box @portfolio.name,
                   at: [0, pdf.bounds.top - 100],
                   width: CONTENT_W,
                   align: :left,
                   leading: 8
    end

    draw_cover_metrics_vertical
  end

  def draw_cover_metrics_vertical
    perf = data[:performance]

    metrics_y = 460
    metric_height = 80
    border_spacing = 16

    metrics = [
      { label: 'Rentabilidade do Ano', value: fmt_pct(perf[:yearly_return]) },
      { label: 'Rentabilidade do Mês', value: fmt_pct(perf[:monthly_return]) },
      { label: 'Ganhos do Mês', value: fmt_cur(perf[:total_earnings]) },
      { label: 'Patrimônio Total', value: fmt_cur(perf[:total_value]) }
    ]

    metrics.each_with_index do |m, i|
      y_pos = metrics_y - (i * (metric_height + border_spacing))

      pdf.font('Plus Jakarta Sans', size: 10) do
        pdf.fill_color C[:body]
        pdf.text_box m[:label],
                     at: [0, y_pos],
                     width: CONTENT_W,
                     align: :left
      end

      pdf.font('Geist Pixel Square', size: 24) do
        pdf.fill_color C[:body]
        pdf.text_box m[:value],
                     at: [0, y_pos - 20],
                     width: CONTENT_W,
                     align: :left
      end

      if i < metrics.size - 1
        pdf.stroke_color C[:border]
        pdf.line_width 0.5
        pdf.stroke_horizontal_line 0, CONTENT_W, at: y_pos - metric_height + 10
      end
    end
  end

  def draw_cover_metrics
    perf = data[:performance]
    metrics = [
      { label: 'Rentabilidade do Mês', value: fmt_pct(perf[:monthly_return]), color: C[:body] },
      { label: 'Rentabilidade do Ano', value: fmt_pct(perf[:yearly_return]), color: C[:body] },
      { label: 'Ganhos do Mês', value: fmt_cur(perf[:total_earnings]), color: C[:body] },
      { label: 'Patrimônio Total', value: fmt_cur(perf[:total_value]), color: C[:body] }
    ]

    card_w = (CONTENT_W - 15) / 2.0
    card_h = 72
    top_y = pdf.bounds.top - 420

    metrics.each_with_index do |m, i|
      x = (i % 2) * (card_w + 15)
      y = top_y - (i / 2) * (card_h + 10)

      pdf.fill_color C[:bg_light]
      pdf.fill { pdf.rounded_rectangle [x, y], card_w, card_h, 0 }

      pdf.fill_color m[:color]
      pdf.fill_rectangle [x, y], 4, card_h

      pdf.fill_color C[:gray]
      pdf.font('Plus Jakarta Sans', size: 9) { pdf.text_box m[:label], at: [x + 12, y - 12], width: card_w - 16 }

      pdf.fill_color m[:color]
      pdf.font('JetBrains Mono', style: :bold, size: 17) { pdf.text_box m[:value], at: [x + 12, y - 34], width: card_w - 16 }
    end
  end

  def render_summary_page
    draw_page(title: 'Desempenho da Carteira') do
      perf = data[:performance]
      bnch = data[:benchmarks]

      cdi_pct = bnch[:cdi][:ytd].to_f > 0 ? (perf[:yearly_return].to_f / bnch[:cdi][:ytd].to_f * 100).round(2) : 0
      ipca_pct = bnch[:ipca][:ytd].to_f > 0 ? (perf[:yearly_return].to_f / bnch[:ipca][:ytd].to_f * 100).round(2) : 0
      ima_pct = bnch[:ima_geral][:ytd].to_f > 0 ? (perf[:yearly_return].to_f / bnch[:ima_geral][:ytd].to_f * 100).round(2) : 0

      draw_section(title: '1. Carteira em Relação aos Índices', border: true, spacing: 25) do
        idx_table = [
          ['Índice', 'Mensal', 'Anual', 'Rentabilidade'],
          ['CDI', fmt_pct(bnch[:cdi][:monthly]), fmt_pct(bnch[:cdi][:ytd]), "#{fmt_num(cdi_pct, 2)}%"],
          ['IPCA', fmt_pct(bnch[:ipca][:monthly]), fmt_pct(bnch[:ipca][:ytd]), "#{fmt_num(ipca_pct, 2)}%"],
          ['IMA-GERAL', fmt_pct(bnch[:ima_geral][:monthly]), fmt_pct(bnch[:ima_geral][:ytd]), "#{fmt_num(ima_pct, 2)}%"],
          ['Ibovespa', fmt_pct(bnch[:ibovespa][:monthly]), fmt_pct(bnch[:ibovespa][:ytd]), '-']
        ]
        styled_table(idx_table, col_widths: [140, 100, 100, 160])
      end

      monthly_returns = build_monthly_returns_series
      meta_series = build_meta_series

      draw_section(title: '2. Rentabilidade Comparada com a Meta', border: true, spacing: 25) do
        draw_line_chart(
          series: [
            { label: 'Carteira', color: C[:primary], points: monthly_returns },
            { label: 'Meta', color: C[:warning], points: meta_series }
          ],
          height: 100, y: pdf.cursor
        )
        pdf.move_down 115
      end

      draw_section(title: '3. Rendimento Mensal', info: "Últimos 12 Meses", border: true, spacing: 25) do
        draw_bar_chart(
          data: data[:monthly_history].map { |m| [short_month(m[:period]), m[:earnings]] },
          height: 90, y: pdf.cursor, color: C[:secondary]
        )
        pdf.move_down 105
      end

      eco = data[:economic_indices]
      draw_section(title: '3. Rentabilidade Comparada com a Meta', border: true, spacing: 0) do
        perf_table = [['Mês', 'Rent. Carteira', 'Meta', 'CDI', 'IPCA']]
        data[:monthly_history].last(6).each do |m|
          per_key = m[:period].beginning_of_month
          cart = monthly_returns.find { |p| p[:period] == per_key }
          perf_table << [
            full_month(m[:period]),
            fmt_pct(cart&.dig(:value) || 0),
            fmt_pct(eco['Meta']&.dig(per_key) || bnch[:meta][:monthly]),
            fmt_pct(eco['CDI']&.dig(per_key) || bnch[:cdi][:monthly]),
            fmt_pct(eco['IPCA']&.dig(per_key) || bnch[:ipca][:monthly])
          ]
        end
        styled_table(perf_table, col_widths: [160, 90, 80, 80, 80])
      end
    end
  end

  def render_fund_details_page
    draw_page(title: 'Carteira de Investimentos') do
      perf_by_fi = (@performance_data[:performances] || []).index_by(&:fund_investment_id)

      fund_rows = [['Fundo', 'Rendimento', 'Movimentação', 'Valor Final', 'Rent.']]

      data[:fund_investments].each do |fi|
        perf = perf_by_fi[fi.id]

        init  = perf&.initial_balance.to_f
        earn  = perf&.earnings.to_f
        apps  = monthly_apps_for(fi)
        reds  = monthly_reds_for(fi)
        move  = apps - reds
        final = init + earn + move
        rent  = perf&.monthly_return.to_f

        fund_rows << [
          truncate(fi.investment_fund.fund_name, 38),
          fmt_cur(earn),
          fmt_cur(move),
          fmt_cur(final),
          fmt_pct(rent)
        ]
      end

      draw_section(
        title: "Carteira de Investimentos",
        info: month_year_label,
        border: true,
        spacing: 20
      ) do
        styled_table(
          fund_rows,
          col_widths: [190, 85, 85, 95, 40]
        )
      end
    end
  end

  def render_monthly_history_page
    draw_page(title: 'Histórico Patrimonial') do
      hist = data[:monthly_history]

      draw_section(title: 'Patrimônio Total por Mês', info: "Gráfico", border: true, spacing: 24) do
        draw_bar_chart(data: hist.map { |m| [short_month(m[:period]), m[:balance]] }, height: 90, y: pdf.cursor, color: C[:secondary])
      end

      pdf.move_down 130

      draw_section(title: 'Patrimônio Total por Mês', info: "Tabela", border: true, spacing: 24) do
        pat_rows = [['Mês', 'Patrimônio Total', 'Rendimento Mensal']]
        hist.each { |m| pat_rows << [full_month(m[:period]), fmt_cur(m[:balance]), fmt_cur(m[:earnings])] }
        styled_table(pat_rows, col_widths: [200, 160, 155])
      end

      pdf.move_down 30

      flows = data[:monthly_flows]

      draw_section(title: 'Movimentações por Mês', info: "Gráfico", border: true, spacing: 0) do
        draw_grouped_bar_chart(
          data: flows.map { |f| [short_month(f[:period]), f[:applications], f[:redemptions]] },
          labels: ['Aplicações', 'Resgates'],
          colors: [C[:success], C[:danger]],
          height: 90, y: pdf.cursor
        )
      end
    end

    draw_page do
      draw_section(title: 'Movimentações por Mês', info: "Tabela", border: true, spacing: 0) do
        flows = data[:monthly_flows]
        flow_rows = [['Mês', 'Aplicações', 'Resgates', 'Movimentação Líquida']]
        flows.each { |f| flow_rows << [full_month(f[:period]), fmt_cur(f[:applications]), fmt_cur(f[:redemptions]), fmt_cur(f[:applications] - f[:redemptions])] }
        styled_table(flow_rows, col_widths: [160, 115, 115, 125])
      end
    end
  end

  def render_fund_distribution_page
    draw_page(title: 'Distribuição') do
      alloc = data[:allocation]
      return if alloc.empty?

      draw_section(title: "Carteira / Fundos", info: "#{month_year_label}", border: true, spacing: 0) do
        draw_allocation_bars(alloc, y: pdf.cursor)
      end
    end
  end

  def render_index_earnings_page
    draw_page(title: 'Rendimento por Índice') do
      idx_groups = data[:index_groups]
      total_earn = idx_groups.values.sum { |v| v[:earnings] }

      draw_section(title: "Rendimento por Benchmark", info: "#{month_year_label}", border: true, spacing: 0) do
        draw_horizontal_bars(data: idx_groups.map { |k, v| { label: k, value: v[:earnings] } }, color: C[:secondary], y: pdf.cursor)
      end

      pdf.move_down 20

      draw_section(title: "Lista de índices", border: true, spacing: 0) do
        earn_rows = [['Índice de Referência', 'Rendimento do Mês', '% do Total']]
        idx_groups.sort_by { |_, v| -v[:earnings] }.each do |k, v|
          pct = total_earn > 0 ? (v[:earnings] / total_earn * 100).round(2) : 0
          earn_rows << [k, fmt_cur(v[:earnings]), fmt_pct(pct)]
        end
        earn_rows << ['Total', fmt_cur(total_earn), '100,00%']
        styled_table(earn_rows, col_widths: [200, 190, 125], last_row_bold: false)
      end
    end
  end

  def render_historical_table_page
    draw_page(title: 'Histórico Mensal') do
      hist = data[:monthly_history]
      hist_rows = [['Mês', 'Patrimônio Total', 'Rendimento Mensal']]
      hist.each { |m| hist_rows << [full_month(m[:period]), fmt_cur(m[:balance]), fmt_cur(m[:earnings])] }
      hist_rows << ['Total', '', fmt_cur(hist.sum { |m| m[:earnings] })]

      draw_section(title: 'Histórico Mensal', border: true, spacing: 22) do
        styled_table(hist_rows, col_widths: [200, 157, 158], last_row_bold: false)
      end

      pdf.move_down 20

      eco = data[:economic_indices]
      bnch = data[:benchmarks]
      idx_tbl = [['Mês', 'Meta', 'IPCA', 'CDI', 'IMA-GERAL', 'Ibovespa']]
      hist.each do |m|
        per = m[:period].beginning_of_month
        idx_tbl << [
          full_month(m[:period]),
          fmt_pct(eco['Meta']&.dig(per) || bnch[:meta][:monthly]),
          fmt_pct(eco['IPCA']&.dig(per) || bnch[:ipca][:monthly]),
          fmt_pct(eco['CDI']&.dig(per) || bnch[:cdi][:monthly]),
          fmt_pct(eco['IMA-GERAL']&.dig(per) || bnch[:ima_geral][:monthly]),
          fmt_pct(eco['Ibovespa']&.dig(per) || bnch[:ibovespa][:monthly])
        ]
      end

      draw_section(title: 'Índices por Mês', border: true, spacing: 0) do
        styled_table(idx_tbl, col_widths: [140, 75, 75, 75, 85, 65])
      end
    end
  end

  def render_accumulated_indices_page
    draw_page(title: 'Índices Acumulados no Ano') do
      perf = data[:performance]
      bnch = data[:benchmarks]

      acc_data = [
        { label: 'Carteira', value: perf[:yearly_return], color: C[:primary] },
        { label: 'Meta', value: bnch[:meta][:ytd], color: C[:warning] },
        { label: 'CDI', value: bnch[:cdi][:ytd], color: C[:accent] },
        { label: 'IPCA', value: bnch[:ipca][:ytd], color: C[:success] },
        { label: 'IMA-GERAL', value: bnch[:ima_geral][:ytd], color: C[:secondary] },
        { label: 'Ibovespa', value: bnch[:ibovespa][:ytd], color: C[:danger] }
      ]

      draw_section(title: 'Rentabilidade Acumulada', info: "Comparativo com Benchmarks", border: true, spacing: 0) do
        draw_comparison_bars(acc_data, y: pdf.cursor)
      end

      pdf.move_down 14

      draw_section(title: 'Rentabilidade Acumulada', info: "Tabela", border: true, spacing: 0) do
        cdi_r = bnch[:cdi][:ytd].to_f > 0 ? (perf[:yearly_return].to_f / bnch[:cdi][:ytd].to_f * 100).round(2) : 0
        ipca_r = bnch[:ipca][:ytd].to_f > 0 ? (perf[:yearly_return].to_f / bnch[:ipca][:ytd].to_f * 100).round(2) : 0
        ima_r = bnch[:ima_geral][:ytd].to_f > 0 ? (perf[:yearly_return].to_f / bnch[:ima_geral][:ytd].to_f * 100).round(2) : 0

        acc_rows = [
          ['Indicador', 'Rent. Acumulada', '% em Relação à Carteira'],
          ['Carteira', fmt_pct(perf[:yearly_return]), '100,00%'],
          ['Meta', fmt_pct(bnch[:meta][:ytd]), '-'],
          ['CDI', fmt_pct(bnch[:cdi][:ytd]), "#{fmt_num(cdi_r, 2)}%"],
          ['IPCA', fmt_pct(bnch[:ipca][:ytd]), "#{fmt_num(ipca_r, 2)}%"],
          ['IMA-GERAL', fmt_pct(bnch[:ima_geral][:ytd]), "#{fmt_num(ima_r, 2)}%"],
          ['Ibovespa', fmt_pct(bnch[:ibovespa][:ytd]), '-']
        ]
        styled_table(acc_rows, col_widths: [160, 170, 185])
      end
    end
  end

  def draw_bar_chart(data:, height:, y:, color: C[:primary])
    chart_style = {
      axes: { color: C[:white], width: 0.5 },
      bars: { width_ratio: 0.7, offset_ratio: 0.15, radius: 2, positive_color: color, negative_color: C[:danger] },
      labels: { font: 'Geist Pixel Square', size: 5.5, color: C[:gray_light], truncate: 4 },
      empty_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:gray], message: 'Dados não disponíveis para o período' },
      error_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:gray], message: 'Erro ao renderizar gráfico' }
    }

    if data.empty?
      pdf.fill_color chart_style[:empty_state][:color]
      pdf.font(chart_style[:empty_state][:font],
               size: chart_style[:empty_state][:size],
               style: :italic) do
        pdf.text_box chart_style[:empty_state][:message],
                     at: [0, y - 20],
                     width: CONTENT_W,
                     align: :center
      end
      return
    end

    values   = data.map { |_, v| v.to_f }
    max_val  = values.max.nonzero? || 1.0
    chart_y  = y - 8
    slot_w = (CONTENT_W - 40) / [data.size, 1].max.to_f

    pdf.stroke_color chart_style[:axes][:color]
    pdf.line_width chart_style[:axes][:width]
    pdf.stroke_horizontal_line 0, CONTENT_W, at: chart_y - height

    data.each_with_index do |(label, val), i|
      val = val.to_f
      bar_height = (val.abs / max_val * (height - 10)).round(1)
      x = i * slot_w + slot_w * chart_style[:bars][:offset_ratio]
      w = slot_w * chart_style[:bars][:width_ratio]
      baseline_y = chart_y - height
      bar_color = val >= 0 ? chart_style[:bars][:positive_color] : chart_style[:bars][:negative_color]

      pdf.fill_color bar_color
      radius = [chart_style[:bars][:radius], bar_height / 2.0].min
      pdf.fill_rounded_rectangle [x, baseline_y + bar_height], w, bar_height, radius

      pdf.fill_color chart_style[:labels][:color]
      pdf.font(chart_style[:labels][:font],
               size: chart_style[:labels][:size]) do
        pdf.draw_text label.to_s[0..chart_style[:labels][:truncate]],
                      at: [x, baseline_y - 9]
      end
    end

  rescue StandardError => e
    Rails.logger.error("Error drawing bar chart: #{e.message}")
    pdf.fill_color chart_style[:error_state][:color]
    pdf.font(chart_style[:error_state][:font],
             size: chart_style[:error_state][:size],
             style: :italic) do
      pdf.text_box chart_style[:error_state][:message],
                   at: [0, y - 20],
                   width: CONTENT_W,
                   align: :center
    end
  end

  def draw_grouped_bar_chart(data:, labels:, colors:, height:, y:)
    chart_style = {
      axes: { color: C[:white], width: 0.5 },
      bars: { width_ratio: 0.9, radius: 2, spacing: 8 },
      labels: { font: 'Geist Pixel Square', size: 5.5, color: C[:muted], truncate: 4 },
      legend: { font: 'Geist Pixel Square', size: 7, text_color: C[:gray], box_width: 10, box_height: 7, radius: 1.5, spacing_x: 80, offset_from_right: 160 },
      empty_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:gray], message: 'Dados não disponíveis para o período' },
      error_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:gray], message: 'Erro ao renderizar gráfico' }
    }

    if data.empty?
      pdf.fill_color chart_style[:empty_state][:color]
      pdf.font(chart_style[:empty_state][:font],
               size: chart_style[:empty_state][:size],
               style: :italic) do
        pdf.text_box chart_style[:empty_state][:message],
                     at: [0, y - 20],
                     width: CONTENT_W,
                     align: :center
      end
      return
    end

    values = data.flat_map { |_, a, b| [a, b] }.map(&:to_f)
    max_val = values.max.nonzero? || 1.0
    group_w = (CONTENT_W - 20) / [data.size, 1].max.to_f
    chart_y = y - 8

    pdf.stroke_color chart_style[:axes][:color]
    pdf.line_width chart_style[:axes][:width]
    pdf.stroke_horizontal_line 0, CONTENT_W, at: chart_y - height

    data.each_with_index do |(label, v1, v2), i|
      x = i * group_w + 4
      bw = (group_w - chart_style[:bars][:spacing]) / 2.0
      base = chart_y - height

      [v1, v2].each_with_index do |val, j|
        bar_height = (val.to_f.abs / max_val * (height - 10)).round(1)
        pdf.fill_color colors[j]
        bar_x = x + j * bw
        bar_w = bw * chart_style[:bars][:width_ratio]
        radius = [chart_style[:bars][:radius], bar_height / 2.0, bar_w / 2.0].min
        pdf.fill_rounded_rectangle [bar_x, base + bar_height], bar_w, bar_height, radius
      end

      pdf.fill_color chart_style[:labels][:color]
      pdf.font(chart_style[:labels][:font],
               size: chart_style[:labels][:size]) do
        pdf.draw_text label.to_s[0..chart_style[:labels][:truncate]],
                      at: [x, base - 9]
      end
    end

    labels.each_with_index do |lbl, i|
      lx = CONTENT_W - chart_style[:legend][:offset_from_right] + i * chart_style[:legend][:spacing_x]
      ly = chart_y + 2
      pdf.fill_color colors[i]
      pdf.fill_rounded_rectangle [lx, ly + chart_style[:legend][:box_height]],
                                 chart_style[:legend][:box_width],
                                 chart_style[:legend][:box_height],
                                 chart_style[:legend][:radius]
      pdf.fill_color chart_style[:legend][:text_color]
      pdf.font(chart_style[:legend][:font],
               size: chart_style[:legend][:size]) do
        pdf.draw_text lbl, at: [lx + 13, ly + 1]
      end
    end

  rescue StandardError => e
    Rails.logger.error("Error drawing grouped bar chart: #{e.message}")
    pdf.fill_color chart_style[:error_state][:color]
    pdf.font(chart_style[:error_state][:font],
             size: chart_style[:error_state][:size],
             style: :italic) do
      pdf.text_box chart_style[:error_state][:message],
                   at: [0, y - 20],
                   width: CONTENT_W,
                   align: :center
    end
  end

  def draw_line_chart(series:, height:, y:)
    chart_style = {
      axes: { color: C[:white], width: 1 },
      line: { width: 1 },
      labels: { font: 'Geist Pixel Square', size: 5, color: C[:gray_light] },
      legend: { font: 'Geist Pixel Square', size: 7, text_color: C[:muted], box_width: 12, box_height: 4, radius: 0.5, spacing_x: 80 },
      empty_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:muted], message: 'Dados não disponíveis para o período' },
      error_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:gray], message: 'Erro ao renderizar gráfico' }
    }

    all_vals = series.flat_map { |s| s[:points].map { |p| p[:value].to_f } }

    if all_vals.empty? || series.first[:points].empty?
      pdf.fill_color chart_style[:empty_state][:color]
      pdf.font(chart_style[:empty_state][:font], size: chart_style[:empty_state][:size]) do
        pdf.text_box chart_style[:empty_state][:message],
                     at: [0, y - 20],
                     width: CONTENT_W,
                     align: :center
      end
      return
    end

    min_val = [all_vals.min.to_f, 0.0].min
    max_val = all_vals.max.to_f
    range   = (max_val - min_val).nonzero? || 1.0
    chart_y  = y - 8
    n_points = series.first[:points].size

    pdf.stroke_color chart_style[:axes][:color]
    pdf.line_width chart_style[:axes][:width]
    pdf.stroke_horizontal_line 0, CONTENT_W, at: chart_y - height
    pdf.stroke_vertical_line chart_y - height, chart_y, at: 0

    series.each do |s|
      pts = s[:points]
      next if pts.size < 2

      pdf.stroke_color s[:color]
      pdf.line_width chart_style[:line][:width]

      coords = pts.map.with_index do |pt, i|
        x = i.to_f / (n_points - 1) * CONTENT_W
        y = chart_y - height + ((pt[:value].to_f - min_val) / range * (height - 12))
        [x, y]
      end

      pdf.stroke do
        pdf.move_to coords[0]

        if coords.size == 2
          pdf.line_to coords[1]
        else
          coords.each_cons(2).with_index do |(p1, p2), i|
            p0 = i > 0 ? coords[i - 1] : p1
            p3 = i < coords.size - 2 ? coords[i + 2] : p2
            cp1_x = p1[0] + (p2[0] - p0[0]) / 6.0
            cp1_y = p1[1] + (p2[1] - p0[1]) / 6.0
            cp2_x = p2[0] - (p3[0] - p1[0]) / 6.0
            cp2_y = p2[1] - (p3[1] - p1[1]) / 6.0
            pdf.curve_to p2, bounds: [[cp1_x, cp1_y], [cp2_x, cp2_y]]
          end
        end
      end
    end

    pts_for_labels = series.first[:points]
    pts_for_labels.each_with_index do |pt, i|
      x = i.to_f / (n_points - 1) * CONTENT_W
      pdf.fill_color chart_style[:labels][:color]
      pdf.font(chart_style[:labels][:font], size: chart_style[:labels][:size]) do
        pdf.draw_text pt[:label].to_s[0..2],
                      at: [x - 6, chart_y - height - 9]
      end
    end

    series.each_with_index do |s, i|
      lx = i * chart_style[:legend][:spacing_x]
      pdf.fill_color s[:color]
      pdf.fill_rounded_rectangle [lx, chart_y + 10],
                                 chart_style[:legend][:box_width],
                                 chart_style[:legend][:box_height],
                                 chart_style[:legend][:radius]
      pdf.fill_color chart_style[:legend][:text_color]
      pdf.font(chart_style[:legend][:font], size: chart_style[:legend][:size]) do
        pdf.draw_text s[:label], at: [lx + 16, chart_y + 6]
      end
    end

  rescue StandardError => e
    Rails.logger.error("Error drawing line chart: #{e.message}")
    pdf.fill_color chart_style[:error_state][:color]
    pdf.font(chart_style[:error_state][:font],
             size: chart_style[:error_state][:size],
             style: :italic) do
      pdf.text_box chart_style[:error_state][:message],
                   at: [0, y - 20],
                   width: CONTENT_W,
                   align: :center
    end
  end

  def draw_allocation_bars(alloc, y:)
    chart_style = {
      bars: { height: 18, spacing: 20, radius: 2, label_width: 160, value_offset: 4 },
      labels: { name_font: 'Geist Pixel Square', name_size: 7, name_color: C[:gray_dark], name_truncate: 28, value_font: 'Geist Pixel Square', value_size: 7, value_color: C[:gray] },
      empty_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:gray], message: 'Não há dados de alocação disponíveis' },
      error_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:gray], message: 'Erro ao renderizar alocação' }
    }

    if alloc.empty?
      pdf.fill_color chart_style[:empty_state][:color]
      pdf.font(chart_style[:empty_state][:font],
               size: chart_style[:empty_state][:size],
               style: :italic) do
        pdf.text_box chart_style[:empty_state][:message],
                     at: [0, y - 20],
                     width: CONTENT_W,
                     align: :center
      end
      pdf.move_down 40
      return
    end

    max_alloc = alloc.map { |a| a[:allocation].to_f }.max.nonzero? || 1.0

    alloc.first(12).each_with_index do |item, i|
      by = y - i * chart_style[:bars][:spacing] - 16
      alloc_f = item[:allocation].to_f
      bar_w = (alloc_f / max_alloc * (CONTENT_W - 200)).round(1)
      color = C[:chart][i % C[:chart].size]

      pdf.fill_color chart_style[:labels][:name_color]
      pdf.font(chart_style[:labels][:name_font],
               size: chart_style[:labels][:name_size]) do
        pdf.draw_text truncate(item[:fund_name].to_s, chart_style[:labels][:name_truncate]),
                      at: [0, by + 6]
      end

      pdf.fill_color color
      radius = [chart_style[:bars][:radius], (chart_style[:bars][:height] - 4) / 2.0].min
      pdf.fill_rounded_rectangle [chart_style[:bars][:label_width], by + chart_style[:bars][:height] - 2],
                                 [bar_w, 1].max,
                                 chart_style[:bars][:height] - 4,
                                 radius

      pdf.fill_color chart_style[:labels][:value_color]
      pdf.font(chart_style[:labels][:value_font],
               size: chart_style[:labels][:value_size]) do
        pdf.draw_text "#{fmt_num(alloc_f, 2)}%",
                      at: [chart_style[:bars][:label_width] + bar_w + chart_style[:bars][:value_offset], by + 6]
      end

      break if by < 20
    end

    pdf.move_down [alloc.size, 12].min * chart_style[:bars][:spacing] + 10

  rescue StandardError => e
    Rails.logger.error("Error drawing allocation bars: #{e.message}")
    pdf.fill_color chart_style[:error_state][:color]
    pdf.font(chart_style[:error_state][:font],
             size: chart_style[:error_state][:size],
             style: :italic) do
      pdf.text chart_style[:error_state][:message]
    end
    pdf.move_down 40
  end

  def draw_horizontal_bars(data:, color:, y:)
    chart_style = {
      bars: { height: 18, spacing: 22, radius: 2, label_width: 170, value_offset: 4 },
      labels: { name_font: 'Geist Pixel Square', name_size: 7, name_color: C[:gray_dark], name_truncate: 26, value_font: 'Geist Pixel Square', value_size: 7, value_color: C[:gray] },
      empty_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:gray], message: 'Dados não disponíveis' },
      error_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:gray], message: 'Erro ao renderizar gráfico' }
    }

    if data.empty?
      pdf.fill_color chart_style[:empty_state][:color]
      pdf.font(chart_style[:empty_state][:font],
               size: chart_style[:empty_state][:size],
               style: :italic) do
        pdf.text_box chart_style[:empty_state][:message],
                     at: [0, y - 20],
                     width: CONTENT_W,
                     align: :center
      end
      pdf.move_down 40
      return
    end

    max_val = data.map { |d| d[:value].to_f }.max.nonzero? || 1.0

    data.first(8).each_with_index do |item, i|
      by = y - i * chart_style[:bars][:spacing] - 16
      bar_w = (item[:value].to_f / max_val * (CONTENT_W - 230)).round(1)

      pdf.fill_color chart_style[:labels][:name_color]
      pdf.font(chart_style[:labels][:name_font],
               size: chart_style[:labels][:name_size]) do
        pdf.draw_text truncate(item[:label].to_s, chart_style[:labels][:name_truncate]),
                      at: [0, by + 6]
      end

      pdf.fill_color color
      radius = [chart_style[:bars][:radius], (chart_style[:bars][:height] - 4) / 2.0].min
      pdf.fill_rounded_rectangle [chart_style[:bars][:label_width], by + chart_style[:bars][:height] - 2],
                                 [bar_w, 1].max,
                                 chart_style[:bars][:height] - 4,
                                 radius

      pdf.fill_color chart_style[:labels][:value_color]
      pdf.font(chart_style[:labels][:value_font],
               size: chart_style[:labels][:value_size]) do
        pdf.draw_text fmt_cur(item[:value]),
                      at: [chart_style[:bars][:label_width] + bar_w + chart_style[:bars][:value_offset], by + 6]
      end

      break if by < 20
    end

    pdf.move_down [data.size, 8].min * chart_style[:bars][:spacing] + 10

  rescue StandardError => e
    Rails.logger.error("Error drawing horizontal bars: #{e.message}")
    pdf.fill_color chart_style[:error_state][:color]
    pdf.font(chart_style[:error_state][:font],
             size: chart_style[:error_state][:size],
             style: :italic) do
      pdf.text chart_style[:error_state][:message]
    end
    pdf.move_down 40
  end

  def draw_comparison_bars(items, y:)
    chart_style = {
      bars: { height: 18, spacing: 26, radius: 2, label_width: 80, value_offset: 6 },
      labels: { name_font: 'Geist Pixel Square', name_size: 8, name_color: C[:muted], value_font: 'Geist Pixel Square', value_size: 8, value_color: C[:muted] }
    }

    max_val = items.map { |i| i[:value].to_f }.max.nonzero? || 1.0

    items.each_with_index do |item, i|
      by = y - i * chart_style[:bars][:spacing] - 16
      bar_w = (item[:value].to_f.abs / max_val * (CONTENT_W - 120)).round(1)

      pdf.fill_color chart_style[:labels][:name_color]
      pdf.font(chart_style[:labels][:name_font],
               size: chart_style[:labels][:name_size]) do
        pdf.draw_text item[:label].to_s, at: [0, by + 6]
      end

      pdf.fill_color item[:color]
      radius = [chart_style[:bars][:radius], (chart_style[:bars][:height] - 4) / 2.0].min
      pdf.fill_rounded_rectangle [chart_style[:bars][:label_width], by + chart_style[:bars][:height] - 2],
                                 [bar_w, 1].max,
                                 chart_style[:bars][:height] - 4,
                                 radius

      pdf.fill_color chart_style[:labels][:value_color]
      pdf.font(chart_style[:labels][:value_font],
               size: chart_style[:labels][:value_size]) do
        pdf.draw_text fmt_pct(item[:value]),
                      at: [chart_style[:bars][:label_width] + bar_w + chart_style[:bars][:value_offset], by + 6]
      end
    end

    pdf.move_down items.size * chart_style[:bars][:spacing] + 10
  end

  def numeric_cell?(cell)
    cell_str = cell.to_s.strip
    return true if cell_str =~ /^R\$\s*-?\d+(\.\d{3})*,\d{2}$/
    return true if cell_str =~ /^-?\d+(,\d+)?%$/
    return true if cell_str =~ /^-?\d+(\.\d{3})*(,\d+)?$/
    false
  end

  def extract_numeric_value(cell)
    cell_str = cell.to_s.strip
    numeric_str = cell_str.gsub(/[R$\s%]/, '').gsub('.', '').gsub(',', '.')
    numeric_str.to_f
  rescue
    0.0
  end

  def color_for_value(value)
    if value < 0
      C[:danger]
    elsif value == 0
      C[:muted]
    else
      C[:success]
    end
  end

  def styled_table(rows, col_widths: nil, last_row_bold: false)
    if rows.size < 2
      pdf.fill_color C[:gray]
      pdf.font('Plus Jakarta Sans', size: 9, style: :italic) do
        pdf.text_box 'Não há dados disponíveis',
                     at: [0, pdf.cursor - 20],
                     width: CONTENT_W,
                     align: :center
      end
      pdf.move_down 40
      return
    end

    sanitized_rows = rows.map do |row|
      row.map { |cell| cell.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?') }
    end

    colors = {
      body:     C[:body],
      bg_light: C[:bg_light],
      white:    C[:white],
      border:   C[:border],
      primary:  C[:primary],
    }

    base_opts = {
      header: true,
      width: CONTENT_W,
      cell_style: {
        font: 'Plus Jakarta Sans',
        size: 8,
        padding: [6, 8],
        borders: %i[top bottom],
        border_color: colors[:border],
        border_width: 1,
        inline_format: true,
        overflow: :shrink_to_fit,
        min_font_size: 8
      }
    }

    base_opts[:column_widths] = col_widths if col_widths

    build_table = lambda do |options|
      pdf.table(sanitized_rows, options) do |t|
        t.row(0).tap do |row|
          row.text_color = colors[:white]
          row.background_color = colors[:primary]
          row.borders = [:top, :bottom]
        end

        (1...sanitized_rows.size).each do |row_idx|
          t.row(row_idx).background_color = colors[:white]

          sanitized_rows[row_idx].each_with_index do |cell_value, col_idx|
            cell = t.cells[row_idx, col_idx]

            if numeric_cell?(cell_value)
              numeric_value = extract_numeric_value(cell_value)
              cell.font = 'IBM Plex Mono'
              cell.text_color = color_for_value(numeric_value)
            else
              numeric_value = extract_numeric_value(cell_value)
              cell.font = 'IBM Plex Mono'
              cell.text_color = color_for_value(numeric_value)
            end
          end
        end

        if last_row_bold && sanitized_rows.size > 1
          last_idx = sanitized_rows.size - 1
          t.row(last_idx).tap do |row|
            row.background_color = colors[:bg_light]
            row.borders = [:top, :bottom],
              row.border_color = colors[:body]
          end

          sanitized_rows[last_idx].each_with_index do |cell_value, col_idx|
            cell = t.cells[last_idx, col_idx]

            if numeric_cell?(cell_value)
              numeric_value = extract_numeric_value(cell_value)
              cell.font = 'Geist Pixel Square'
              cell.text_color = color_for_value(numeric_value)
            else
              cell.text_color = colors[:body]
            end
          end
        end
      end
    end

    build_table.call(base_opts)

  rescue Prawn::Errors::CannotFit
    begin
      build_table.call(base_opts.except(:column_widths))
    rescue StandardError
      pdf.font('Plus Jakarta Sans', size: 7) do
        sanitized_rows.each { |row| pdf.text row.join(' | ') }
      end
    end
  end

  def page_header(title)
    pdf.pad 20 do
      pdf.font('Geist Pixel Square', size: 24) do
        pdf.text_box title.to_s.upcase, width: CONTENT_W - 140
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

  def draw_page(title: nil, first_page: false)
    pdf.start_new_page unless first_page
    page_header(title) if title.present?
    yield if block_given?
  end

  def draw_section(title: nil, info: nil, border: true, spacing: 20)
    pdf.pad 10 do
      if title
        start_y = pdf.cursor

        pdf.fill_color C[:body]
        pdf.font('Geist Pixel Square', size: 14) do
          pdf.draw_text title.to_s.upcase, at: [0, start_y]
        end

        if info
          pdf.fill_color C[:muted]
          pdf.font('Geist Pixel Square', size: 8) do
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

  def draw_kpi_row(kpis, y:)
    card_w = (CONTENT_W - (kpis.size - 1) * 8.0) / kpis.size
    card_h = 52

    kpis.each_with_index do |kpi, i|
      x = i * (card_w + 8)
      pdf.fill_color C[:bg_light]
      pdf.fill { pdf.rounded_rectangle [x, y], card_w, card_h, 0 }
      pdf.fill_color C[:gray]
      pdf.font('Plus Jakarta Sans', size: 7) { pdf.text_box kpi[:label], at: [x + 7, y - 8], width: card_w - 10 }
      pdf.fill_color kpi[:color]
      pdf.font('JetBrains Mono', style: :bold, size: 9) { pdf.text_box kpi[:value], at: [x + 7, y - 24], width: card_w - 10 }
    end

    pdf.move_down card_h + 8
  end

  def build_monthly_returns_series
    data[:monthly_history].map do |m|
      perfs = @portfolio.performance_histories
                        .where(period: m[:period])
                        .includes(fund_investment: :investment_fund)

      alloc_total = perfs.sum { |p| p.fund_investment.percentage_allocation.to_f }
      weighted = perfs.sum { |p| p.monthly_return.to_f * p.fund_investment.percentage_allocation.to_f }
      ret = alloc_total > 0 ? (weighted / alloc_total) : 0.0

      { period: m[:period].beginning_of_month, value: ret, label: short_month(m[:period]) }
    end
  end

  def build_meta_series
    eco = data[:economic_indices]
    bnch = data[:benchmarks]
    data[:monthly_history].map do |m|
      per = m[:period].beginning_of_month
      val = eco['Meta']&.dig(per) || bnch[:meta][:monthly]
      { period: per, value: val.to_f, label: short_month(m[:period]) }
    end
  end

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

  def fmt_cur(value)
    ActionController::Base.helpers.number_to_currency(
      value.to_f, unit: 'R$', separator: ',', delimiter: '.', precision: 2
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
    day = date.day
    month = I18n.l(date, format: '%B')
    year = date.year
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
    I18n.l(@reference_date, format: '%B de %Y').capitalize
  rescue StandardError
    @reference_date.strftime('%B de %Y')
  end
end