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
    @requested_reference_date = reference_date.dup  # ← primeiro, antes de tudo
    @performance_data = collect_performance_data     # ← pode mutar @reference_date
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
    render_distribution_donuts_page
    render_index_earnings_page
    render_index_patrimony_page       # NOVO — Patrimônio por Índice em página própria
    render_historical_table_page
    render_asset_type_page
    render_accumulated_indices_page
    render_investment_policy_page
    render_investment_policy_page   # Image 1 — 4 grupos de barras por artigo
    stamp_global_footer
    stamp_watermark                   # NOVO — Marca d'água em todas as páginas
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
      "Geist Mono" => {
        normal: Rails.root.join("app/assets/fonts/GeistMono-Regular.ttf"),
        bold: Rails.root.join("app/assets/fonts/GeistMono-Semibold.ttf"),
      },
      "Geist" => {
        normal: Rails.root.join("app/assets/fonts/Geist-Regular.ttf"),
        bold: Rails.root.join("app/assets/fonts/Geist-Semibold.ttf"),
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
      economic_indices: collect_economic_indices_history,
      investment_policy: collect_investment_policy_data,
      policy_compliance: calculate_policy_compliance,
      checking_accounts: collect_checking_accounts        # NOVO
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

    # Ganhos do mês: usa total_gain (mark-to-market, fonte de verdade)
    monthly_earnings = @portfolio.total_gain.to_f

    # Ganhos acumulados do ano:
    # - Se é janeiro, é igual ao mês (não há meses anteriores no ano)
    # - Se é fevereiro em diante, soma os earnings históricos dos meses anteriores
    #   mais o ganho atual
    yearly_earnings = if @reference_date.month == 1
                        monthly_earnings
                      else
                        prior_months_earnings = @portfolio.performance_histories
                                                          .where(period: @reference_date.beginning_of_year...@reference_date.beginning_of_month)
                                                          .sum(:earnings).to_f
                        prior_months_earnings + monthly_earnings
                      end

    {
      monthly_return:  portfolio_monthly,
      yearly_return:   portfolio_yearly,
      total_earnings:  monthly_earnings,   # ← era total_gain, agora é só o mês
      yearly_earnings: yearly_earnings,
      total_value:     total_value,
      initial_balance: total_initial,
      performances:    performances
    }
  end

  def empty_performance
    { monthly_return: 0.0, yearly_return: 0.0, total_earnings: 0.0,
      yearly_earnings: 0.0, total_value: 0.0, initial_balance: 0.0, performances: [] }
  end

  # Mapeia a abbreviation exata do banco para a chave simbólica usada no relatório.
  # Centralizado aqui para evitar que divergências de string silenciem índices.
  BENCHMARK_KEY_MAP = {
    'CDI'      => :cdi,
    'IPCA'     => :ipca,
    'IMAGERAL' => :ima_geral,
    'IBOVESPA' => :ibovespa,
  }.freeze

  def collect_benchmark_data
    indices = EconomicIndex.all.index_by(&:abbreviation)
    result  = {}

    BENCHMARK_KEY_MAP.each do |abbr, key|
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

      result[key] = { monthly: monthly, ytd: ytd }
    end

    # Explanation:: META = taxa de juros anual do portfolio (pro-rata mensal) + IPCA do mês/ano.
    #               O juros anual é dividido por 12 para obter a parcela mensal,
    #               e somado diretamente ao acumulado anual de IPCA para o YTD.
    ipca_monthly = result.dig(:ipca, :monthly).to_f
    ipca_ytd     = result.dig(:ipca, :ytd).to_f
    meta_monthly   = @portfolio.annual_interest_rate.to_f + ipca_monthly
    meta_ytd     = @portfolio.annual_interest_rate.to_f + ipca_ytd
    result[:meta] = { monthly: meta_monthly, ytd: meta_ytd }

    %i[cdi ipca ima_geral ibovespa meta].each { |k| result[k] ||= { monthly: 0.0, ytd: 0.0 } }
    result
  rescue StandardError => e
    Rails.logger.error("Error collecting benchmark data: #{e.message}")
    {
      cdi:      { monthly: 0.0, ytd: 0.0 },
      ipca:     { monthly: 0.0, ytd: 0.0 },
      ima_geral:{ monthly: 0.0, ytd: 0.0 },
      ibovespa: { monthly: 0.0, ytd: 0.0 },
      meta:     { monthly: 0.0, ytd: 0.0 }
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
      ref_idx = fi.investment_fund.benchmark_index.presence || '-'  # ← aqui
      groups[ref_idx][:allocation] += fi.percentage_allocation.to_f
      groups[ref_idx][:value]      += fi.current_market_value.to_f
      groups[ref_idx][:earnings]   += fi.total_gain.to_f
    end

    groups
  end

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

      label = [article.article_number.presence, article.article_name.presence].compact.join(': ').presence || "Art. ##{article.id}"

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
        current:      current_alloc.round(2),
        target:       tgt_v,
        min:          min_v,
        max:          max_v,
        within_range: within
      }
    end

    result
  rescue StandardError => e
    Rails.logger.error("Error calculating policy compliance: #{e.message}")
    {}
  end

  def calculate_institution_groups
    groups = Hash.new { |h, k| h[k] = { value: 0.0, allocation: 0.0 } }
    @portfolio.fund_investments.includes(:investment_fund).each do |fi|
      inst = fi.investment_fund.administrator_name.presence || 'Outros'
      groups[inst][:value]      += fi.current_market_value.to_f
      groups[inst][:allocation] += fi.percentage_allocation.to_f
    end
    groups
  end

  # == calculate_asset_type_groups
  #
  # @author Moisés Reis
  # @category Model
  #
  # Category:: Agrupa os valores financeiros e rendimentos dos investimentos baseando-se
  #            na categoria normativa de cada fundo para fins de relatório.
  #            Organiza os totais em um formato de lista para o gráfico.
  #
  # Attributes:: - *groups* - um dicionário que armazena os totais por categoria.
  #
  def calculate_asset_type_groups
    groups = Hash.new { |h, k| h[k] = { value: 0.0, earnings: 0.0 } }
    perf_by_fi = (@performance_data[:performances] || []).index_by(&:fund_investment_id)

    @portfolio.fund_investments
              .includes(investment_fund: { investment_fund_articles: :normative_article }).each do |fi|
      # Explanation:: Busca a categoria do artigo normativo ou define como padrão 'Renda Fixa Geral'.
      #               Isso garante que todos os ativos tenham uma classificação visual.
      articles = fi.investment_fund.investment_fund_articles
      label = articles.any? ? (articles.first.normative_article&.category.presence || 'Renda Fixa Geral') : 'Renda Fixa Geral'

      groups[label][:value]    += fi.current_market_value.to_f
      groups[label][:earnings] += fi.total_gain.to_f
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

  # Coleta artigos normativos e monta estrutura para o gráfico de política.
  # Cada entrada: { label, article_number, carteira_atual, alvo, minimo, maximo }
  # Requer colunas minimum_target e maximum_target em normative_articles
  # (ver migration abaixo). Usa try para não quebrar se ainda não existirem.
  def collect_investment_policy_data
    # Mapeia article_id → soma de percentage_allocation dos fund_investments do portfolio
    alloc_by_article = Hash.new(0.0)
    @portfolio.fund_investments
              .includes(investment_fund: { investment_fund_articles: :normative_article })
              .each do |fi|
      fi.investment_fund.investment_fund_articles.each do |ifa|
        next unless ifa.normative_article
        alloc_by_article[ifa.normative_article.id] += fi.percentage_allocation.to_f
      end
    end

    # Busca todos os artigos únicos do portfólio
    article_ids = alloc_by_article.keys
    return [] if article_ids.empty?

    NormativeArticle.where(id: article_ids).map do |art|
      carteira_atual = alloc_by_article[art.id].round(4)
      alvo           = art.benchmark_target.to_f
      minimo         = art.try(:minimum_target).to_f
      maximo         = art.try(:maximum_target).to_f

      # Conformidade: dentro do intervalo [mínimo, máximo]
      compliant = if maximo > 0 || minimo > 0
                    carteira_atual >= minimo && (maximo.zero? || carteira_atual <= maximo)
                  else
                    true  # sem limites definidos → conforme por padrão
                  end

      {
        id:            art.id,
        label:         art.display_name,
        article_number: art.article_number.presence || art.article_name.presence || "Art. ##{art.id}",
        carteira_atual: carteira_atual,
        alvo:           alvo,
        minimo:         minimo,
        maximo:         maximo,
        compliant:      compliant
      }
    end
  end

  # == collect_checking_accounts
  #
  # Coleta os registros de contas correntes do portfólio para o mês de referência.
  # Retorna array de hashes com name, institution, account_number, balance e notes.
  # Tolerante a erros — retorna [] se a tabela ainda não existir.
  #
  def collect_checking_accounts
    ref         = @requested_reference_date
    month_start = ref.beginning_of_month
    month_end   = ref.end_of_month

    ::CheckingAccount                                          # ← :: adicionado
      .where(portfolio: @portfolio, reference_date: month_start..month_end)
      .order(:institution, :name)
      .map do |ca|
      {
        name:           ca.name,
        institution:    ca.institution,
        account_number: ca.account_number.presence || '-',
        balance:        ca.balance.to_f,
        notes:          ca.notes.presence || '-'
      }
    end
  rescue StandardError => e
    Rails.logger.warn("[PortfolioMonthlyReportGenerator] collect_checking_accounts: #{e.message}")
    Rails.logger.debug(e.backtrace.first(3).join("\n"))
    []
  end

  # ─── FOOTER ─────────────────────────────────────────────────────────────────

  def stamp_global_footer
    pdf.repeat(:all) do
      footer_y = -MARGIN_B + 10

      pdf.font('Geist Pixel Square', size: 6) do
        pdf.fill_color C[:gray_light]
        page_text = "#{pdf.page_number} de #{pdf.page_count}"
        text_width = pdf.width_of(page_text)
        pdf.draw_text(page_text, at: [CONTENT_W - text_width, footer_y + 4])
      end
    end
  end

  # == stamp_watermark
  #
  # Aplica logo.png como marca dagua em todas as paginas exceto a capa (pagina 1).
  # Usa on_page_create para registrar um callback que desenha a imagem a cada nova
  # pagina criada, e go_to_page para aplicar retroativamente nas paginas ja existentes.
  # Pagina 1 (capa) e pulada explicitamente pelo guard "next if page_num == 1".
  #
  WATERMARK_IMAGE_PATH = Rails.root.join('app', 'assets', 'images', 'logo.png').freeze
  WATERMARK_WIDTH      = 380

  def stamp_watermark
    return unless File.exist?(WATERMARK_IMAGE_PATH)

    wm_w = WATERMARK_WIDTH.to_f

    # Coordenadas: centro da area util da pagina
    img_x = (CONTENT_W - wm_w) / 2.0
    img_y = (PAGE_H - MARGIN_T - MARGIN_B) / 2.0 + (wm_w / 2.0)

    draw_wm = lambda do
      next if pdf.page_number == 1

      pdf.save_graphics_state do
        pdf.rotate(45, origin: [CONTENT_W / 2.0, (PAGE_H - MARGIN_T - MARGIN_B) / 2.0]) do
          pdf.fill_color 'dddddd'
          pdf.image WATERMARK_IMAGE_PATH.to_s, at: [img_x, img_y], width: wm_w
        end
      end
    end

    # Aplica nas paginas ja criadas (todas exceto pagina 1)
    total = pdf.page_count
    (2..total).each do |page_num|
      pdf.go_to_page(page_num)
      pdf.transparent(0.03) do
        pdf.rotate(45, origin: [CONTENT_W / 2.0, (PAGE_H - MARGIN_T - MARGIN_B) / 2.0]) do
          pdf.image WATERMARK_IMAGE_PATH.to_s, at: [img_x, img_y], width: wm_w
        end
      end
    end

    # Garante que paginas criadas depois tambem recebam a marca
    pdf.on_page_create { draw_wm.call }
  rescue StandardError => e
    Rails.logger.warn("[PortfolioMonthlyReportGenerator] stamp_watermark: #{e.message}")
  end

  # ─── CAPA ────────────────────────────────────────────────────────────────────

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

    metrics_y     = 460
    metric_height = 80
    border_spacing = 16

    # Linha 1: Rentabilidade do Ano
    metrics = [
      { label: 'Rentabilidade do Ano',  value: fmt_pct(perf[:yearly_return]),  sub: nil },
      { label: 'Rentabilidade do Mês',  value: fmt_pct(perf[:monthly_return]), sub: nil },
      {
        label:     'Ganhos do Mês',
        value:     fmt_cur(perf[:total_earnings]),
      },
      {
        label: 'Ganhos Acumulados do Ano',
        value: fmt_cur(perf[:yearly_earnings])
      },
      {
        label:     'Total da Carteira de Investimentos',
        value:     fmt_cur(perf[:total_value]),
      }
    ]

    metrics.each_with_index do |m, i|
      y_pos = metrics_y - (i * (metric_height + border_spacing))

      pdf.font('Plus Jakarta Sans', size: 10) do
        pdf.fill_color C[:body]
        pdf.text_box m[:label],
                     at: [0, y_pos],
                     width: CONTENT_W / 2,
                     align: :left
      end

      # Sub-label (e.g. "Ganhos acumulados do ano") no lado direito
      if m[:sub_label]
        pdf.font('Plus Jakarta Sans', size: 9) do
          pdf.fill_color C[:muted]
          pdf.text_box m[:sub_label],
                       at: [CONTENT_W / 2, y_pos],
                       width: CONTENT_W / 2,
                       align: :left
        end
      end

      pdf.font('Geist Pixel Square', size: 24) do
        pdf.fill_color C[:body]
        pdf.text_box m[:value],
                     at: [0, y_pos - 20],
                     width: CONTENT_W / 2,
                     align: :left
      end

      if m[:sub_value]
        pdf.font('Geist Pixel Square', size: 14) do
          pdf.fill_color C[:muted]
          pdf.text_box m[:sub_value],
                       at: [CONTENT_W / 2, y_pos - 20],
                       width: CONTENT_W / 2,
                       align: :left
        end
      end

      if m[:note]
        pdf.font('Plus Jakarta Sans', size: 7) do
          pdf.fill_color C[:danger]
          pdf.text_box m[:note],
                       at: [0, y_pos - 46],
                       width: CONTENT_W,
                       align: :left
        end
      end

      if i < metrics.size - 1
        pdf.stroke_color C[:border]
        pdf.line_width 0.5
        pdf.stroke_horizontal_line 0, CONTENT_W, at: y_pos - metric_height + 10
      end
    end
  end

  # ─── DESEMPENHO ──────────────────────────────────────────────────────────────

  def render_summary_page
    draw_page(title: 'Desempenho da Carteira') do
      perf = data[:performance]
      bnch = data[:benchmarks]

      cdi_pct  = bnch[:cdi][:ytd].to_f  > 0 ? (perf[:yearly_return].to_f / bnch[:cdi][:ytd].to_f  * 100).round(2) : 0
      ipca_pct = bnch[:ipca][:ytd].to_f > 0 ? (perf[:yearly_return].to_f / bnch[:ipca][:ytd].to_f * 100).round(2) : 0
      ima_pct  = bnch[:ima_geral][:ytd].to_f > 0 ? (perf[:yearly_return].to_f / bnch[:ima_geral][:ytd].to_f * 100).round(2) : 0

      monthly_returns = build_monthly_returns_series
      meta_series     = build_meta_series

      draw_section(title: 'Rentabilidade da Carteira', info: "Mês a Mês", border: true, spacing: 25) do
        bar_data = monthly_returns.zip(meta_series).map do |cart, meta|
          [cart[:label], cart[:value].to_f, meta[:value].to_f]
        end
        draw_grouped_bar_chart(
          data: bar_data,
          labels: ['Carteira', 'Meta'],
          colors: [C[:primary], C[:warning]],
          height: 100, y: pdf.cursor
        )
        pdf.move_down 115
      end

      pdf.move_down 20
      eco = data[:economic_indices]

      draw_section(title: 'Rentabilidade Comparada com a Meta', info: "Tabela", border: true, spacing: 0) do
        perf_table = [['Mês', 'Rent. Carteira', 'Meta', 'CDI', 'IPCA']]
        data[:monthly_history].last(6).each do |m|
          per_key = m[:period].beginning_of_month
          cart = monthly_returns.find { |p| p[:period] == per_key }
          perf_table << [
            full_month(m[:period]),
            fmt_pct(cart&.dig(:value) || 0),
            fmt_pct(meta_monthly_series[per_key][:meta]),
            fmt_pct(eco['CDI']&.dig(per_key)   || bnch[:cdi][:monthly]),
            fmt_pct(eco['IPCA']&.dig(per_key)  || bnch[:ipca][:monthly])
          ]
        end
        styled_table(perf_table, col_widths: [160, 90, 80, 80, 80])
      end

      pdf.start_new_page

      # ── Gauge: Rentabilidade em relação à Meta ────────────────────────────────
      meta_r_gauge = bnch[:meta][:ytd].to_f > 0 ? (perf[:yearly_return].to_f / bnch[:meta][:ytd].to_f * 100).round(2) : 0.0

      draw_section(title: 'Rentabilidade em Relação à Meta', border: true, spacing: 10) do
        gauge_cx = CONTENT_W / 4.0
        gauge_cy = pdf.cursor - 70
        draw_gauge_meter(
          value:   meta_r_gauge,
          max:     200.0,
          cx:      gauge_cx,
          cy:      gauge_cy,
          radius:  65
        )

        # ── Barras "Carteira em relação aos índices" à direita do gauge ──────
        rel_x   = CONTENT_W / 2.0 + 10
        rel_top = pdf.cursor - 10

        pdf.fill_color C[:body]
        pdf.font('Geist', size: 10) do
          pdf.draw_text 'CARTEIRA EM RELAÇÃO AOS ÍNDICES:', at: [rel_x, rel_top]
        end

        rel_items = [
          { label: 'Do CDI%',      value: cdi_pct,  color: C[:secondary] },
          { label: 'Do IPCA%',     value: ipca_pct, color: C[:secondary] },
          { label: 'Do IMA%',      value: ima_pct,  color: C[:secondary] }
        ]

        bar_max  = rel_items.map { |r| r[:value].to_f }.max.nonzero? || 1.0
        bar_area = CONTENT_W - rel_x - 80
        bar_h    = 14
        gap      = 22

        rel_items.each_with_index do |item, idx|
          by    = rel_top - 22 - idx * gap
          bar_w = (item[:value].to_f / bar_max * bar_area).round(1)

          pdf.fill_color C[:muted]
          pdf.font('Geist Pixel Square', size: 7) do
            pdf.draw_text item[:label], at: [rel_x, by + 4]
          end

          pdf.fill_color item[:color]
          pdf.fill_rounded_rectangle [rel_x + 55, by + bar_h - 2],
                                     [bar_w, 1].max, bar_h - 2, 2

          pdf.fill_color C[:muted]
          pdf.font('Geist Pixel Square', size: 8) do
            pdf.draw_text "#{fmt_num(item[:value], 2)}%",
                          at: [rel_x + 55 + bar_w + 5, by + 4]
          end
        end

        pdf.move_down 155
      end

      draw_section(title: 'Carteira em Relação aos Índices', border: true, spacing: 25) do
        idx_table = [
          ['Índice',    'Mensal',                              'Anual',                           'Rentabilidade'],
          ['CDI',       fmt_pct(bnch[:cdi][:monthly]),       fmt_pct(bnch[:cdi][:ytd]),       "#{fmt_num(cdi_pct,  2)}%"],
          ['IPCA',      fmt_pct(bnch[:ipca][:monthly]),      fmt_pct(bnch[:ipca][:ytd]),      "#{fmt_num(ipca_pct, 2)}%"],
          ['IMA-GERAL', fmt_pct(bnch[:ima_geral][:monthly]), fmt_pct(bnch[:ima_geral][:ytd]), "#{fmt_num(ima_pct,  2)}%"],
          ['Ibovespa',  fmt_pct(bnch[:ibovespa][:monthly]),  fmt_pct(bnch[:ibovespa][:ytd]),  '-'],
          ['Carteira',  fmt_pct(perf[:monthly_return]),      fmt_pct(perf[:yearly_return]),   '100,00%']
        ]
        styled_table(idx_table, col_widths: [140, 100, 100, 160])
      end

      pdf.move_down 20

      draw_section(title: 'Rendimento Mensal', info: "Mês a Mês", border: true, spacing: 25) do
        draw_bar_chart(
          data: data[:monthly_history].map { |m| [short_month(m[:period]), m[:earnings]] },
          height: 90, y: pdf.cursor, color: C[:secondary]
        )
        pdf.move_down 105
      end
    end
  end

  # ─── CARTEIRA DE INVESTIMENTOS ───────────────────────────────────────────────

  def render_fund_details_page
    draw_page(title: 'Carteira de Investimentos') do
      perf_by_fi = (@performance_data[:performances] || []).index_by(&:fund_investment_id)

      fund_rows = [['Fundo', 'Rendimento', 'Movimentação', 'Valor Final', 'Rentabilidade']]

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

      draw_section(title: "Carteira de Investimentos", info: month_year_label, border: true, spacing: 20) do
        styled_table(fund_rows, col_widths: [190, 85, 85, 95, 40])
      end

      pdf.move_down 40

      accounts = data[:checking_accounts]

      total_balance = accounts.sum { |a| a[:balance] }

      draw_section(title: "Relação de Contas Correntes", info: month_year_label, border: true, spacing: 0) do
        rows = [['Instituição', 'Nome / Descrição', 'Nº da Conta', 'Saldo', '% do Total']]

        accounts.sort_by { |a| -a[:balance] }.each do |a|
          pct = total_balance > 0 ? (a[:balance] / total_balance * 100).round(2) : 0
          rows << [
            truncate(a[:institution], 20),
            truncate(a[:name], 22),
            a[:account_number],
            fmt_cur(a[:balance]),
            fmt_pct(pct)
          ]
        end

        # Linha de total
        rows << ['', 'Total das Disponibilidades', '', fmt_cur(total_balance), '100,00%']

        col_widths = [110, 130, 80, 100, 95]

        pdf.table(
          rows.map { |r| r.map { |c| c.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?') } },
          header: true,
          width: CONTENT_W,
          column_widths: col_widths,
          cell_style: {
            font: 'Plus Jakarta Sans',
            size: 8,
            padding: [5, 7],
            borders: %i[top bottom],
            border_color: C[:border],
            border_width: 1,
            text_color: C[:body]
          }
        ) do |t|
          t.row(0).tap do |r|
            r.text_color       = C[:white]
            r.background_color = C[:primary]
          end

          (1...rows.size - 1).each { |ri| t.row(ri).background_color = C[:white] }

          # Última linha (total) em destaque
          last = rows.size - 1
          t.row(last).background_color = C[:bg_light]
          t.row(last).borders          = %i[top bottom]
          t.row(last).border_color     = C[:body]
          t.cells[last, 3].font        = 'Geist Pixel Square'
          t.cells[last, 3].size        = 9
          t.cells[last, 3].text_color  = C[:primary]
        end
      rescue Prawn::Errors::CannotFit
        styled_table(rows)
      end

      pdf.start_new_page

      # ── Relação dos fundos e ativos ──
      draw_section(title: "Relação dos Fundos e Ativos", border: true, spacing: 20) do
        rel_rows = [['CNPJ do Fundo', 'Nome do Fundo', 'Enq. 4.963/21', 'Índice de Ref.', 'Taxa Adm.']]

        data[:fund_investments].each do |fi|
          fund = fi.investment_fund
          cnpj = fund.cnpj.presence || '-'
          enq  = fund.investment_fund_articles.first&.normative_article&.article_name || '-'
          ref  = fund.benchmark_index.presence || '-'
          adm  = fund.administration_fee.present? ? "#{fmt_num(fund.administration_fee.to_f, 2)}%" : '-'

          rel_rows << [cnpj, truncate(fund.fund_name, 26), enq, ref, adm]
        end

        styled_table(rel_rows, col_widths: [100, 155, 80, 65, 45])
      end
    end
  end

  # ─── HISTÓRICO PATRIMONIAL ───────────────────────────────────────────────────

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
        draw_waterfall_chart(flows: flows, height: 90, y: pdf.cursor)
      end
    end

    draw_page do
      draw_section(title: 'Movimentações por Mês', info: "Tabela", border: true, spacing: 0) do
        flows = data[:monthly_flows]
        flow_rows = [['Mês', 'Aplicações', 'Resgates', 'Movimentação Líquida']]
        flows.each { |f| flow_rows << [full_month(f[:period]), fmt_cur(f[:applications]), fmt_cur(f[:redemptions]), fmt_cur(f[:applications] - f[:redemptions])] }
        styled_table(flow_rows, col_widths: [160, 115, 115, 125])
      end

      pdf.move_down 20

      hist          = data[:monthly_history]   # ← adicione esta linha
      accounts      = data[:checking_accounts]
      total_balance = accounts.sum { |a| a[:balance] }

      draw_section(title: 'Evolução do Patrimônio', info: "Últimos 12 meses", border: true, spacing: 25) do
        draw_bar_chart(
          data: hist.map { |m|
            balance = m[:balance]
            balance += total_balance if m[:period].beginning_of_month == @reference_date.beginning_of_month
            [short_month(m[:period]), balance]
          },
          height: 90,
          y: pdf.cursor,
          color: C[:primary]
        )
        pdf.move_down 105
      end
    end
  end

  def render_distribution_donuts_page
    draw_page(title: 'Distribuição da Carteira') do

      # ── 1. Donut por Índice de Referência ─────────────────────────────────────
      draw_section(title: 'Distribuição por Índice de Referência', border: true, spacing: 10) do
        idx_data = data[:index_groups]
                     .map    { |k, v| { label: k, value: v[:allocation] } }
                     .reject { |d| d[:value] <= 0 }
                     .sort_by { |d| -d[:value] }

        total_idx = idx_data.sum { |d| d[:value] }

        cx = 130
        cy = pdf.cursor - 90

        draw_donut_chart(
          data:     idx_data,
          cx:       cx,
          cy:       cy,
          radius:   80,
          legend_x: cx + 95,
          legend_y: cy + 70
        )

        pdf.move_down 185

        # Mini-tabela abaixo do donut
        rows = [['Índice', 'Alocação', '% do Total']]
        idx_data.each do |d|
          pct = total_idx > 0 ? (d[:value] / total_idx * 100) : 0
          rows << [d[:label], fmt_pct(d[:value]), fmt_pct(pct)]
        end
        rows << ['Total', fmt_pct(total_idx), '100,00%']
        styled_table(rows, col_widths: [200, 150, 165])
      end

      pdf.move_down 30

      # ── 2. Donut por Categoria de Artigo Normativo ────────────────────────────
      draw_section(title: 'Distribuição por Categoria Normativa', border: true, spacing: 10) do
        # Agrupa alocação por category do artigo normativo
        category_groups = Hash.new(0.0)

        data[:fund_investments].each do |fi|
          alloc = fi.percentage_allocation.to_f
          arts  = fi.investment_fund.investment_fund_articles

          if arts.any?
            arts.each do |ifa|
              cat = ifa.normative_article&.category.presence || 'Não Classificado'
              category_groups[cat] += alloc / arts.size
            end
          else
            category_groups['Não Classificado'] += alloc
          end
        end

        cat_data = category_groups
                     .map    { |k, v| { label: k, value: v } }
                     .reject { |d| d[:value] <= 0 }
                     .sort_by { |d| -d[:value] }

        # Cores fixas por categoria
        category_colors = {
          'Renda Fixa'           => C[:primary],
          'Renda Variável'       => C[:secondary],
          'Investimento Exterior' => C[:warning],
          'Não Classificado'     => C[:muted]
        }
        cat_data.each { |d| d[:color] = category_colors[d[:label]] }

        total_cat = cat_data.sum { |d| d[:value] }

        cx = 130
        cy = pdf.cursor - 90

        draw_donut_chart(
          data:     cat_data,
          cx:       cx,
          cy:       cy,
          radius:   80,
          legend_x: cx + 95,
          legend_y: cy + 50
        )

        pdf.move_down 185

        rows = [['Categoria', 'Alocação', '% do Total']]
        cat_data.each do |d|
          pct = total_cat > 0 ? (d[:value] / total_cat * 100) : 0
          rows << [d[:label], fmt_pct(d[:value]), fmt_pct(pct)]
        end
        rows << ['Total', fmt_pct(total_cat), '100,00%']
        styled_table(rows, col_widths: [200, 150, 165])
      end
    end
  end

  # ─── DISTRIBUIÇÃO ────────────────────────────────────────────────────────────

  def render_fund_distribution_page
    draw_page(title: 'Distribuição') do
      alloc = data[:allocation]
      return if alloc.empty?

      draw_section(title: "Distribuição da carteira por Fundos", info: month_year_label, border: true, spacing: 0) do
        draw_allocation_bars(alloc, y: pdf.cursor)
      end

      pdf.move_down 20

      # Donut — Distribuição por Fundos
      idx_groups = data[:index_groups]
      donut_data = idx_groups.map { |k, v| { label: k, value: v[:allocation] } }
                             .sort_by { |d| -d[:value] }

      draw_donut_chart(
        data:      donut_data,
        cx:        120,
        cy:        pdf.cursor - 80,
        radius:    70,
        legend_x:  210,
        legend_y:  pdf.cursor - 30
      )
      pdf.move_down 160

      # ── Distribuição por Instituição Financeira ──
      inst_groups = data[:institution_groups]
      unless inst_groups.empty?
        draw_section(title: "Distribuição por Instituição Financeira", border: true, spacing: 0) do
          inst_data = inst_groups.map { |k, v| { label: k, value: v[:value] } }
                                 .sort_by { |d| -d[:value] }
          draw_horizontal_bars(data: inst_data, color: C[:primary], y: pdf.cursor)
        end
      end
    end

    # ── Política de Investimentos ──
    compliance = data[:policy_compliance]
    return if compliance.empty?

    draw_page(title: 'Política de Investimentos') do
      draw_section(
        title: "Carteira em Relação à Política de Investimentos",
        info: month_year_label,
        border: true,
        spacing: 0
      ) do
        draw_policy_compliance_bars(compliance, y: pdf.cursor)
      end

      pdf.move_down 20

      draw_section(title: "Resumo por Artigo", border: true, spacing: 0) do
        tbl_rows = [['Artigo', 'Carteira Atual', 'Alvo', 'Máximo', 'Mínimo', 'Status']]
        compliance.each do |_key, v|
          status_icon = v[:within_range] ? '✓' : '!'
          tbl_rows << [
            truncate(v[:display_name], 30),
            "#{fmt_num(v[:current], 2)}%",
            v[:target] > 0 ? "#{fmt_num(v[:target], 2)}%" : '-',
            v[:max]    ? "#{fmt_num(v[:max],    2)}%" : '-',
            v[:min]    ? "#{fmt_num(v[:min],    2)}%" : '-',
            status_icon
          ]
        end
        styled_table(tbl_rows, col_widths: [155, 70, 70, 70, 70, 80])
      end
    end
  end

  # ─── RENDIMENTO POR ÍNDICE ───────────────────────────────────────────────────

  def render_index_earnings_page
    draw_page(title: 'Rendimento por Índice de Referência') do
      idx_groups = data[:index_groups]
      total_earn = idx_groups.values.sum { |v| v[:earnings] }

      # Rendimento por índice de referência
      draw_section(title: "Rendimento por Índice de Referência", info: month_year_label, border: true, spacing: 0) do
        earn_data = idx_groups.map { |k, v| { label: k, value: v[:earnings] } }
                              .sort_by { |d| -d[:value] }
        draw_horizontal_bars(data: earn_data, color: C[:secondary], y: pdf.cursor)
      end

      pdf.move_down 20

      # Distribuição das aplicações por Índice de Referência
      draw_section(title: "Distribuição das Aplicações por Índice de Referência", border: true, spacing: 20) do
        earn_rows = [['Índice de Referência', 'Rendimento do Mês', '% do Total']]
        idx_groups.sort_by { |_, v| -v[:earnings] }.each do |k, v|
          pct = total_earn > 0 ? (v[:earnings] / total_earn * 100).round(2) : 0
          earn_rows << [k, fmt_cur(v[:earnings]), fmt_pct(pct)]
        end
        earn_rows << ['Total', fmt_cur(total_earn), '100,00%']
        styled_table(earn_rows, col_widths: [200, 190, 125], last_row_bold: false)
      end

      # Patrimônio por Índice de Referência do Mês
      total_value_idx = idx_groups.values.sum { |v| v[:value] }
      draw_section(title: "Patrimônio por Índice de Referência do Mês", border: true, spacing: 0) do
        pat_data = idx_groups.map { |k, v| { label: k, value: v[:value] } }
                             .sort_by { |d| -d[:value] }
        draw_horizontal_bars(data: pat_data, color: C[:primary], y: pdf.cursor)
      end
    end

    draw_page do
      donut_idx = data[:index_groups].map { |k, v| { label: k, value: v[:value] } }
                                     .sort_by { |d| -d[:value] }

      draw_donut_chart(
        data:     donut_idx,
        cx:       120,
        cy:       pdf.cursor - 80,
        radius:   70,
        legend_x: 210,
        legend_y: pdf.cursor - 30
      )
      pdf.move_down 160
    end
  end

  # ─── PATRIMÔNIO POR ÍNDICE (página própria) ──────────────────────────────────

  # == render_index_patrimony_page
  #
  # Página dedicada ao gráfico "Patrimônio por Índice de Referência do Mês",
  # conforme imagem de referência. Exibe barras horizontais por índice (cor primary)
  # e uma tabela resumo abaixo, com enquadramento normativo via legenda de artigos.
  #
  def render_index_patrimony_page
    idx_groups = data[:index_groups]
    return if idx_groups.empty?

    draw_page(title: 'Patrimônio por Índice de Referência') do
      total_value_idx = idx_groups.values.sum { |v| v[:value] }

      # Gráfico de barras horizontais — Patrimônio
      draw_section(title: "Patrimônio por Índice de Referência do Mês", info: month_year_label, border: true, spacing: 0) do
        pat_data = idx_groups.map { |k, v| { label: k, value: v[:value] } }
                             .sort_by { |d| -d[:value] }
        draw_horizontal_bars(data: pat_data, color: C[:primary], y: pdf.cursor)
      end

      pdf.move_down 20

      # Tabela resumo de patrimônio por índice
      draw_section(title: "Distribuição do Patrimônio por Índice de Referência", border: true, spacing: 0) do
        rows = [['Índice de Referência', 'Patrimônio do Mês', '% do Total']]
        idx_groups.sort_by { |_, v| -v[:value] }.each do |k, v|
          pct = total_value_idx > 0 ? (v[:value] / total_value_idx * 100).round(2) : 0
          rows << [k, fmt_cur(v[:value]), fmt_pct(pct)]
        end
        rows << ['Total', fmt_cur(total_value_idx), '100,00%']
        styled_table(rows, col_widths: [200, 190, 125], last_row_bold: false)
      end

      pdf.move_down 20

      # Legenda de enquadramento normativo (referência às imagens)
      draw_compliance_legend
    end
  end

  # ─── PATRIMÔNIO E RENDIMENTO POR TIPO DE ATIVO (página própria com gráficos e legenda) ──

  # ─── CONTAS CORRENTES ────────────────────────────────────────────────────────

  # == render_checking_accounts_page
  #
  # Página dedicada às Contas Correntes do portfólio para o mês de referência.
  # Exibe:
  #   1. Gráfico de barras horizontais com o saldo por conta
  #   2. Tabela detalhada com nome, instituição, número e saldo
  #   3. Total consolidado das disponibilidades
  #
  def render_checking_accounts_page
    accounts = data[:checking_accounts]

    draw_page(title: 'Contas Correntes') do
      if accounts.empty?
        pdf.move_down 20
        pdf.fill_color C[:muted]
        pdf.font('Plus Jakarta Sans', size: 10, style: :italic) do
          pdf.text_box 'Não há contas correntes registradas para este mês.',
                       at: [0, pdf.cursor], width: CONTENT_W, align: :center
        end
        pdf.move_down 40
        next
      end

      total_balance = accounts.sum { |a| a[:balance] }

      # ── Gráfico de barras horizontais ─────────────────────────────────────
      draw_section(title: "Saldo por Conta Corrente", info: month_year_label, border: true, spacing: 0) do
        bar_data = accounts.map { |a| { label: "#{a[:institution]} — #{a[:name]}", value: a[:balance] } }
                           .sort_by { |d| -d[:value] }
        draw_horizontal_bars(data: bar_data, color: C[:secondary], y: pdf.cursor)
      end

      pdf.move_down 20

      # ── Tabela detalhada ──────────────────────────────────────────────────
      draw_section(title: "Relação de Contas Correntes", border: true, spacing: 0) do
        rows = [['Instituição', 'Nome / Descrição', 'Nº da Conta', 'Saldo', '% do Total']]

        accounts.sort_by { |a| -a[:balance] }.each do |a|
          pct = total_balance > 0 ? (a[:balance] / total_balance * 100).round(2) : 0
          rows << [
            truncate(a[:institution], 20),
            truncate(a[:name], 22),
            a[:account_number],
            fmt_cur(a[:balance]),
            fmt_pct(pct)
          ]
        end

        # Linha de total
        rows << ['', 'Total das Disponibilidades', '', fmt_cur(total_balance), '100,00%']

        col_widths = [110, 130, 80, 100, 95]

        pdf.table(
          rows.map { |r| r.map { |c| c.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?') } },
          header: true,
          width: CONTENT_W,
          column_widths: col_widths,
          cell_style: {
            font: 'Plus Jakarta Sans',
            size: 8,
            padding: [5, 7],
            borders: %i[top bottom],
            border_color: C[:border],
            border_width: 1,
            text_color: C[:body]
          }
        ) do |t|
          t.row(0).tap do |r|
            r.text_color       = C[:white]
            r.background_color = C[:primary]
          end

          (1...rows.size - 1).each { |ri| t.row(ri).background_color = C[:white] }

          # Última linha (total) em destaque
          last = rows.size - 1
          t.row(last).background_color = C[:bg_light]
          t.row(last).borders          = %i[top bottom]
          t.row(last).border_color     = C[:body]
          t.cells[last, 3].font        = 'Geist Pixel Square'
          t.cells[last, 3].size        = 9
          t.cells[last, 3].text_color  = C[:primary]
        end
      rescue Prawn::Errors::CannotFit
        styled_table(rows)
      end
    end
  end

  # ─── HISTÓRICO MENSAL ────────────────────────────────────────────────────────

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

      eco  = data[:economic_indices]
      bnch = data[:benchmarks]
      idx_tbl = [['Mês', 'Meta', 'IPCA', 'CDI', 'IMA-GERAL', 'Ibovespa']]
      hist.each do |m|
        per = m[:period].beginning_of_month
        idx_tbl << [
          full_month(m[:period]),
          fmt_pct(meta_monthly_series[per][:meta]),
          fmt_pct(eco['IPCA']&.dig(per)      || bnch[:ipca][:monthly]),
          fmt_pct(eco['CDI']&.dig(per)       || bnch[:cdi][:monthly]),
          fmt_pct(eco['IMAGERAL']&.dig(per)  || bnch[:ima_geral][:monthly]),
          fmt_pct(eco['IBOVESPA']&.dig(per)  || bnch[:ibovespa][:monthly])
        ]
      end

      draw_section(title: 'Índices por Mês', border: true, spacing: 0) do
        styled_table(idx_tbl, col_widths: [140, 75, 75, 75, 85, 65])
      end
    end
  end

  # ─── POLÍTICA DE INVESTIMENTOS (Image 1) ─────────────────────────────────────
  #
  # Página com 4 grupos de barras horizontais:
  #   - Carteira Atual por Artigo
  #   - Alvo Carteira por Artigo
  #   - Máximo por Artigo
  #   - Mínimo por Artigo
  # Cada grupo mostra uma barra por artigo normativo, colorida pelo tipo de ativo.
  #
  def render_investment_policy_page
    policy = data[:investment_policy]
    return if policy.nil? || policy.empty?

    # Cores fixas por artigo (mesmas do reference — azul escuro e azul claro)
    article_colors = {
      'Art. 7º, Inciso I "b"'   => '1a237e',   # azul escuro — 100% Títulos Públicos
      'Art. 7º, Inciso III "a"' => '1976d2'    # azul claro  — Renda Fixa Geral
    }
    default_colors = C[:chart]

    draw_page(title: 'Política de Investimentos') do
      # Título centralizado
      pdf.fill_color C[:body]
      pdf.font('Plus Jakarta Sans', size: 10, style: :bold) do
        label = "Carteira de Investimentos em Relação a Política de Investimentos - #{@reference_date.year}:"
        pdf.text_box label, at: [0, pdf.cursor], width: CONTENT_W, align: :center
      end
      pdf.move_down 20

      groups = [
        { title: 'Carteira Atual por Artigo', key: :carteira_atual },
        { title: 'Alvo Carteira por Artigo',  key: :alvo           },
        { title: 'Máximo por Artigo',         key: :maximo         },
        { title: 'Mínimo por Artigo',         key: :minimo         }
      ]

      groups.each do |grp|
        # Título do grupo
        pdf.fill_color C[:body]
        pdf.font('Plus Jakarta Sans', size: 9, style: :bold) do
          pdf.text_box grp[:title], at: [0, pdf.cursor], width: CONTENT_W, align: :center
        end
        pdf.move_down 16

        max_pct = policy.map { |a| a[grp[:key]].to_f }.max
        max_pct = [max_pct, 1.0].max

        label_w = 130
        bar_area = CONTENT_W - label_w - 60
        bar_h    = 14
        gap      = 20

        policy.each_with_index do |art, idx|
          val     = art[grp[:key]].to_f
          bar_w   = (val / max_pct * bar_area).round(1)
          bar_w   = [bar_w, val > 0 ? 1.0 : 0].max
          color   = article_colors[art[:article_number]] ||
                    default_colors[idx % default_colors.size]
          by      = pdf.cursor - (idx * gap) - bar_h

          # Label do artigo
          pdf.fill_color C[:muted]
          pdf.font('Geist Pixel Square', size: 6.5) do
            pdf.draw_text truncate(art[:article_number], 24), at: [0, by + 3]
          end

          # Barra
          pdf.fill_color color
          pdf.fill_rounded_rectangle [label_w, by + bar_h], [bar_w, 0.5].max, bar_h - 2, 2

          # Valor
          pdf.fill_color C[:muted]
          pdf.font('Geist Pixel Square', size: 6.5) do
            pdf.draw_text "#{fmt_num(val, 2)}%", at: [label_w + bar_w + 4, by + 3]
          end
        end

        pdf.move_down policy.size * gap + 8

        # Legenda "Tipo de Ativo"
        draw_policy_legend(policy, article_colors, default_colors)
        pdf.move_down 16
      end
    end
  end

  # Helper: legenda "Tipo de Ativo ● 100% Títulos Públicos ● Renda Fixa Geral"
  def draw_policy_legend(policy, article_colors, default_colors)
    legend_items = policy.map.with_index do |art, idx|
      color = article_colors[art[:article_number]] || default_colors[idx % default_colors.size]
      label = art[:article_number]
      { color: color, label: label }
    end

    ly = pdf.cursor
    x  = 0

    pdf.fill_color C[:muted]
    pdf.font('Plus Jakarta Sans', size: 6.5) do
      pdf.draw_text 'Tipo de Ativo', at: [x, ly]
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

  # == render_asset_type_page
  #
  # @author Moisés Reis
  # @category View
  #
  # Category:: Desenha a página de patrimônio e rendimento dividida por tipos de ativos.
  #            Exibe barras horizontais coloridas de acordo com a categoria do investimento.
  #            Utiliza dados processados do portfólio para gerar o visual.
  #
  # Attributes:: - *asset_groups* - a lista de ativos agrupados por categoria.
  #
  def render_asset_type_page
    asset_groups = data[:asset_type_groups]
    return if asset_groups.empty?

    # Explanation:: Define as cores baseadas nas categorias normativas (ex: Renda Fixa).
    #               Substitui o mapeamento antigo que dependia do nome específico do artigo.
    category_colors = {
      'Renda Fixa Geral'             => '1a237e',
      '100% Títulos Públicos'         => '1976d2',
      'Investimento Exterior'  => '42a5f5',
      'Renda Fixa'       => '607d8b'
    }

    draw_page(title: 'Patrimônio por Tipo de Ativo') do
      # ── 1. Patrimônio ──────────────────────────────────────────────────────────
      draw_section(title: 'Patrimônio por Tipo de Ativo do Mês', info: month_year_label, border: true, spacing: 0) do
        draw_asset_type_bars(
          asset_groups:    asset_groups,
          value_key:       :value,
          format:          :currency,
          category_colors: category_colors
        )
      end

      pdf.move_down 4
      # Explanation:: Gera a legenda dinamicamente baseada nas categorias presentes no gráfico.
      #               Isso evita exibir artigos que não possuem saldo no mês atual.
      draw_dynamic_enquadramento_legend(asset_groups.keys, category_colors)
      pdf.move_down 16

      # ── 2. Rendimento ──────────────────────────────────────────────────────────
      draw_section(title: 'Rendimento por Tipo de Ativo do Mês', info: month_year_label, border: true, spacing: 0) do
        draw_asset_type_bars(
          asset_groups:    asset_groups,
          value_key:       :earnings,
          format:          :currency,
          category_colors: category_colors
        )
      end

      pdf.move_down 4
      draw_dynamic_enquadramento_legend(asset_groups.keys, category_colors)
    end
  end

  # == draw_asset_type_bars
  #
  # @author Moisés Reis
  # @category Helper
  #
  # Category:: Renderiza as barras horizontais representando os valores de cada categoria.
  #            Calcula o tamanho proporcional da barra e aplica a cor correspondente.
  #            Exibe o nome da categoria à esquerda e o valor formatado à direita.
  #
  # Attributes:: - *category_colors* - mapa de cores por nome de categoria.
  #
  def draw_asset_type_bars(asset_groups:, value_key:, format:, category_colors:)
    label_w  = 130
    bar_area = CONTENT_W - label_w - 70
    bar_h    = 16
    gap      = 28

    max_val = asset_groups.values.map { |v| v[value_key].to_f }.max.nonzero? || 1.0

    asset_groups.sort_by { |_, v| -v[value_key].to_f }.each_with_index do |(category_label, vals), i|
      val    = vals[value_key].to_f
      bar_w  = (val.abs / max_val * bar_area).round(1)
      bar_w  = [bar_w, val != 0 ? 1.0 : 0].max

      # Explanation:: Obtém a cor diretamente da categoria, usando uma cor padrão caso não exista.
      #               Isso remove a necessidade de procurar qual artigo pertence a qual categoria.
      color = category_colors[category_label] || '607d8b'
      by    = pdf.cursor - (i * gap) - bar_h

      pdf.fill_color '666666'
      pdf.font('Geist Pixel Square', size: 7) do
        pdf.draw_text truncate(category_label, 22), at: [0, by + 4]
      end

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

  # ─── PATRIMÔNIO POR TIPO DE ATIVO (página nova) ──────────────────────────────

  def render_asset_type_page
    asset_groups = data[:asset_type_groups]
    return if asset_groups.empty?

    draw_page(title: 'Patrimônio por Tipo de Ativo') do
      # Gráfico de patrimônio por tipo
      draw_section(title: "Patrimônio por Tipo de Ativo do Mês", info: month_year_label, border: true, spacing: 0) do
        pat_data = asset_groups.map { |k, v| { label: k, value: v[:value] } }
                               .sort_by { |d| -d[:value] }
        draw_horizontal_bars(data: pat_data, color: C[:primary], y: pdf.cursor)
      end

      pdf.move_down 6
      draw_compliance_legend
      pdf.move_down 10

      # Gráfico de rendimento por tipo
      draw_section(title: "Rendimento por Tipo de Ativo do Mês", info: month_year_label, border: true, spacing: 0) do
        earn_data = asset_groups.map { |k, v| { label: k, value: v[:earnings] } }
                                .sort_by { |d| -d[:value] }
        draw_horizontal_bars(data: earn_data, color: C[:secondary], y: pdf.cursor)
      end

      pdf.move_down 6
      draw_compliance_legend

      pdf.move_down 20
    end
  end

  # ─── ÍNDICES ACUMULADOS ──────────────────────────────────────────────────────

  def render_accumulated_indices_page
    draw_page(title: 'Índices Acumulados no Ano') do
      perf = data[:performance]
      bnch = data[:benchmarks]
      eco  = data[:economic_indices]

      # Valores YTD — fonte única para barras, tabela e gauge
      meta_ytd = bnch[:meta][:ytd].to_f
      cart_ytd = perf[:yearly_return].to_f
      cdi_ytd  = bnch[:cdi][:ytd].to_f
      ipca_ytd = bnch[:ipca][:ytd].to_f
      ima_ytd  = bnch[:ima_geral][:ytd].to_f
      ibov_ytd = bnch[:ibovespa][:ytd].to_f

      # % da carteira em relação a cada índice acumulado
      safe_div = ->(num, den) { den > 0 ? (num / den * 100).round(2) : 0 }
      meta_r = safe_div.call(cart_ytd, meta_ytd)
      cdi_r  = safe_div.call(cart_ytd, cdi_ytd)
      ipca_r = safe_div.call(cart_ytd, ipca_ytd)
      ima_r  = safe_div.call(cart_ytd, ima_ytd)
      ibov_r = safe_div.call(cart_ytd, ibov_ytd)

      acc_data = [
        { label: 'Meta Acumulado',         value: meta_ytd,  color: C[:warning]   },
        { label: 'Rentabilidade Carteira',  value: cart_ytd,  color: C[:primary]   },
        { label: 'IPCA Acumulado',          value: ipca_ytd,  color: C[:danger]    },
        { label: 'CDI Acumulado',           value: cdi_ytd,   color: C[:success]   },
        { label: 'IMA-GERAL Acumulado',     value: ima_ytd,   color: C[:secondary] },
        { label: 'Ibovespa Acumulado',      value: ibov_ytd,  color: C[:warning]   }
      ]

      # Percentuais de cada índice em relação à Meta (para label duplo nas barras)
      relatives = {
        'Meta Acumulado'        => safe_div.call(meta_ytd,  meta_ytd),
        'Rentabilidade Carteira'=> meta_r,
        'IPCA Acumulado'        => safe_div.call(ipca_ytd,  meta_ytd),
        'CDI Acumulado'         => safe_div.call(cdi_ytd,   meta_ytd),
        'IMA-GERAL Acumulado'   => safe_div.call(ima_ytd,   meta_ytd),
        'Ibovespa Acumulado'    => safe_div.call(ibov_ytd,  meta_ytd)
      }

      draw_section(title: 'Índices Acumulados', info: @reference_date.year.to_s,
                   border: true, spacing: 0) do
        draw_comparison_bars_labeled(acc_data, relatives: relatives, y: pdf.cursor)
      end

      pdf.move_down 14

      draw_section(title: 'Rentabilidade Acumulada',
                   info: "Tabela — Referência: Meta", border: true, spacing: 0) do
        acc_rows = [
          ['Indicador',   'Rent. Acumulada',  '% em Relação à Meta'],
          ['Carteira',    fmt_pct(cart_ytd),  "#{fmt_num(meta_r,  2)}%"],
          ['Meta',        fmt_pct(meta_ytd),  '100,00%'],
          ['CDI',         fmt_pct(cdi_ytd),   "#{fmt_num(cdi_r,   2)}%"],
          ['IPCA',        fmt_pct(ipca_ytd),  "#{fmt_num(ipca_r,  2)}%"],
          ['IMA-GERAL',   fmt_pct(ima_ytd),   "#{fmt_num(ima_r,   2)}%"],
          ['Ibovespa',    fmt_pct(ibov_ytd),  "#{fmt_num(ibov_r,  2)}%"]
        ]
        styled_table(acc_rows, col_widths: [160, 170, 185])
      end

      pdf.move_down 20

      # ── Tabela: Índices por Mês (todos os 12 meses do ano corrente) ──────────
      draw_section(title: 'Índices por Mês', border: true, spacing: 0) do
        rows = [['Ano', 'Mês', 'Meta', 'CDI', 'IPCA', 'Ibovespa', 'IMA-GERAL']]

        # Meses com dados — do início do ano até o mês de referência
        (1..@reference_date.month).each do |month|
          date       = Date.new(@reference_date.year, month, 1)
          period_key = date.beginning_of_month
          rows << [
            date.year,
            I18n.l(date, format: '%B'),
            fmt_pct(meta_monthly_series[period_key][:meta]),
            fmt_pct(eco['CDI']&.dig(period_key)      || 0),
            fmt_pct(eco['IPCA']&.dig(period_key)     || 0),
            fmt_pct(eco['IBOVESPA']&.dig(period_key) || 0),
            fmt_pct(eco['IMAGERAL']&.dig(period_key) || 0)
          ]
        end

        # Meses futuros — placeholder com 0,00% só na coluna Meta
        ((@reference_date.month + 1)..12).each do |month|
          date = Date.new(@reference_date.year, month, 1)
          rows << [date.year, I18n.l(date, format: '%B'), '0,00%', '', '', '', '']
        end

        styled_table(rows, col_widths: [35, 75, 65, 65, 65, 75, 75])
      end
    end
  end

  # == draw_comparison_bars_labeled
  #
  # Variante de draw_comparison_bars que exibe um label duplo:
  # o valor absoluto acumulado + o percentual em relação à Meta entre parênteses.
  # Ex: "1,29% (164,02%)"
  #
  def draw_comparison_bars_labeled(items, relatives:, y:)
    chart_style = {
      bars:   { height: 18, spacing: 26, radius: 2, label_width: 150, value_offset: 6 },
      labels: { name_font: 'Geist Pixel Square', name_size: 8, name_color: C[:muted],
                value_font: 'Geist Pixel Square', value_size: 8, value_color: C[:muted] }
    }

    max_val = items.map { |i| i[:value].to_f.abs }.max.nonzero? || 1.0

    items.each_with_index do |item, i|
      by    = y - i * chart_style[:bars][:spacing] - 16
      bar_w = (item[:value].to_f.abs / max_val * (CONTENT_W - 170)).round(1)

      pdf.fill_color chart_style[:labels][:name_color]
      pdf.font(chart_style[:labels][:name_font], size: chart_style[:labels][:name_size]) do
        pdf.draw_text item[:label].to_s, at: [0, by + 6]
      end

      pdf.fill_color item[:color]
      radius = [chart_style[:bars][:radius], (chart_style[:bars][:height] - 4) / 2.0].min
      pdf.fill_rounded_rectangle [chart_style[:bars][:label_width], by + chart_style[:bars][:height] - 2],
                                 [bar_w, 1].max, chart_style[:bars][:height] - 4, radius

      # Label duplo: "1,29% (164,02%)"
      rel = relatives[item[:label]].to_f
      val_label = rel > 0 ? "#{fmt_pct(item[:value])} (#{fmt_num(rel, 2)}%)" : fmt_pct(item[:value])

      pdf.fill_color chart_style[:labels][:value_color]
      pdf.font(chart_style[:labels][:value_font], size: chart_style[:labels][:value_size]) do
        pdf.draw_text val_label,
                      at: [chart_style[:bars][:label_width] + bar_w + chart_style[:bars][:value_offset], by + 6]
      end
    end

    pdf.move_down items.size * chart_style[:bars][:spacing] + 10
  rescue StandardError => e
    Rails.logger.error("draw_comparison_bars_labeled: #{e.message}")
    pdf.move_down 40
  end

  # ─── CHARTS ──────────────────────────────────────────────────────────────────

  # == draw_gauge_meter
  #
  # Desenha um velocímetro semicircular (gauge) no PDF.
  # O arco vai de 180° (esquerda) até 0° (direita), passando pelo topo em 90°.
  # A agulha é representada por um arco preenchido proporcional ao value/max.
  #
  # @param value  [Float]  valor atual a exibir (ex: 164.02)
  # @param max    [Float]  valor máximo da escala (padrão: 200.0)
  # @param cx     [Float]  centro X do arco
  # @param cy     [Float]  centro Y do arco
  # @param radius [Float]  raio externo do gauge
  #
  def draw_gauge_meter(value:, max: 200.0, cx:, cy:, radius: 65)
    hole_ratio  = 0.55
    inner_r     = radius * hole_ratio
    steps       = 80      # suavidade do arco
    bg_color    = 'e8e8e8'
    fill_color  = C[:secondary]

    # O semicírculo vai de 180° até 0° (sentido horário, topo = 90°)
    start_deg = 180.0
    end_deg   = 0.0

    # ── Arco de fundo (cinza) ────────────────────────────────────────────────
    build_arc_points = lambda do |from_deg, to_deg, r_outer, r_inner, n|
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

    bg_pts = build_arc_points.call(start_deg, end_deg, radius, inner_r, steps)
    pdf.fill_color bg_color
    pdf.fill_polygon(*bg_pts)

    # ── Arco preenchido (proporcional ao value) ──────────────────────────────
    clamped    = [[value.to_f, 0].max, max].min
    fill_ratio = clamped / max
    fill_end   = start_deg + (end_deg - start_deg) * fill_ratio   # negativo → vai p/ direita

    if fill_ratio > 0.005
      fill_pts = build_arc_points.call(start_deg, fill_end, radius, inner_r, [steps, 3].max)
      pdf.fill_color fill_color
      pdf.fill_polygon(*fill_pts)
    end

    # ── Linha divisória no 100% (metade do arco = 90°) ───────────────────────
    half_x = cx + radius * Math.cos(90.0 * Math::PI / 180.0)
    half_y = cy + radius * Math.sin(90.0 * Math::PI / 180.0)
    in_x   = cx + inner_r * Math.cos(90.0 * Math::PI / 180.0)
    in_y   = cy + inner_r * Math.sin(90.0 * Math::PI / 180.0)

    pdf.stroke_color C[:white]
    pdf.line_width 1.2
    pdf.stroke_line [in_x, in_y], [half_x, half_y]

    # ── Buraco central branco ────────────────────────────────────────────────
    pdf.fill_color C[:white]
    # Semicírculo interno — preenche a área do buraco no semicírculo
    hole_pts = build_arc_points.call(start_deg, end_deg, inner_r, 0.01, steps)
    pdf.fill_polygon(*hole_pts)

    # ── Valor central ────────────────────────────────────────────────────────
    val_str = "#{fmt_num(value.to_f, 2)}%"
    pdf.fill_color C[:body]
    pdf.font('Geist Pixel Square', size: 13) do
      vw = pdf.width_of(val_str)
      pdf.draw_text val_str, at: [cx - vw / 2.0, cy - 14]
    end

    # ── Labels min / max ────────────────────────────────────────────────────
    pdf.fill_color C[:muted]
    pdf.font('Geist Pixel Square', size: 6) do
      pdf.draw_text '0,00%',       at: [cx - radius - 2,  cy - 14]
      pdf.draw_text "#{fmt_num(max, 2)}%", at: [cx + inner_r + 4, cy - 14]
    end

  rescue StandardError => e
    Rails.logger.error("draw_gauge_meter: #{e.message}")
  end

  # Página: "Carteira de Investimentos em Relação à Política de Investimentos"
  # Gráfico horizontal mostrando 4 grupos (Mínimo, Máximo, Alvo, Carteira atual),
  # cada um com uma barra por artigo normativo.
  # Abaixo: tabela de conformidade com ícone ✓/✗ por artigo.
  #
  # Requer migration:
  #   add_column :normative_articles, :minimum_target, :decimal, precision: 8, scale: 4
  #   add_column :normative_articles, :maximum_target, :decimal, precision: 8, scale: 4
  def render_investment_policy_page
    policy = data[:investment_policy]
    return if policy.nil? || policy.empty?

    draw_page(title: 'Política de Investimentos') do
      draw_section(title: 'Carteira de Investimentos em Relação à Política de Investimentos',
                   border: true, spacing: 0) do
        draw_horizontal_policy_chart(articles: policy, y: pdf.cursor)
      end
    end
  end

  # Gráfico horizontal de barras agrupadas para política de investimentos.
  # 4 grupos no eixo Y: Mínimo, Máximo, Alvo, Carteira atual.
  # Para cada grupo, uma barra horizontal por artigo (cores distintas).
  # Valor percentual exibido no final de cada barra.
  # Eixo X com ticks de percentual.
  def draw_horizontal_policy_chart(articles:, y:)
    return if articles.empty?

    # Dimensões gerais
    label_w  = 80          # largura da área do label Y
    chart_w  = CONTENT_W - label_w - 30
    bar_h    = 10          # altura de cada barra individual
    bar_gap  = 3           # espaço entre barras do mesmo grupo
    group_gap = 18         # espaço entre grupos
    groups   = ['Mínimo', 'Máximo', 'Alvo', 'Carteira atual']

    # Cores para cada artigo
    art_colors = [C[:primary], C[:secondary]] + C[:chart]

    # Maior valor para escala do eixo X
    all_vals = articles.flat_map { |a| [a[:minimo], a[:maximo], a[:alvo], a[:carteira_atual]] }
    x_max    = ([all_vals.max.to_f, 1.0].max * 1.15).round(0)
    x_max    = ((x_max / 10.0).ceil * 10).to_f   # arredonda para próximo múltiplo de 10

    # Altura total do gráfico (4 grupos × (n_barras × bar_h + gaps) + group_gaps)
    n_arts = articles.size
    group_h  = n_arts * (bar_h + bar_gap) - bar_gap + 4
    total_h  = groups.size * group_h + (groups.size - 1) * group_gap + 30

    chart_top   = y - 10
    chart_left  = label_w
    chart_bottom = chart_top - total_h

    # ── Eixo X — linhas de grade e ticks ──────────────────────────────────────
    tick_count = 9   # 0%, 10%, 20%... 80%, 90%
    tick_vals  = tick_count.times.map { |i| (x_max / (tick_count - 1) * i).round(1) }

    pdf.save_graphics_state do
      tick_vals.each do |tv|
        tx = chart_left + (tv / x_max * chart_w)
        pdf.stroke_color C[:border]
        pdf.line_width 0.3
        pdf.stroke_vertical_line chart_bottom, chart_top, at: tx

        pdf.fill_color C[:muted]
        pdf.font('Geist Pixel Square', size: 5) do
          lbl = "#{fmt_num(tv, 2)}%"
          lw  = pdf.width_of(lbl)
          pdf.draw_text lbl, at: [tx - lw / 2, chart_bottom - 9]
        end
      end
    end

    # Linha de eixo X no fundo
    pdf.stroke_color C[:border]
    pdf.line_width 0.5
    pdf.stroke_horizontal_line chart_left, chart_left + chart_w, at: chart_bottom

    # ── Barras por grupo ──────────────────────────────────────────────────────
    groups.each_with_index do |grp_label, gi|
      gy = chart_top - gi * (group_h + group_gap)

      # Label do grupo (eixo Y)
      pdf.fill_color C[:body]
      pdf.font('Plus Jakarta Sans', size: 8) do
        lw = pdf.width_of(grp_label)
        pdf.draw_text grp_label, at: [label_w - lw - 6, gy - (group_h / 2.0) + 4]
      end

      articles.each_with_index do |art, ai|
        val = case grp_label
              when 'Mínimo'        then art[:minimo]
              when 'Máximo'        then art[:maximo]
              when 'Alvo'          then art[:alvo]
              when 'Carteira atual' then art[:carteira_atual]
              end

        by     = gy - ai * (bar_h + bar_gap)
        bar_w  = x_max > 0 ? (val.to_f / x_max * chart_w) : 0
        bar_w  = [bar_w, 0.5].max

        # Barra
        pdf.fill_color art_colors[ai % art_colors.size]
        radius = [(bar_h - 2) / 2.0, 2].min
        pdf.fill_rounded_rectangle [chart_left, by], [bar_w, chart_w].min, bar_h - 1, radius

        # Valor no final da barra
        pdf.fill_color C[:body]
        pdf.font('Geist Pixel Square', size: 5) do
          lbl = "#{fmt_num(val.to_f, 2)}%"
          pdf.draw_text lbl, at: [chart_left + bar_w + 3, by - 6]
        end
      end
    end

    # ── Legenda ───────────────────────────────────────────────────────────────
    legend_y = chart_bottom - 20
    articles.each_with_index do |art, i|
      lx = i * ((CONTENT_W - label_w) / [articles.size, 1].max) + label_w
      pdf.fill_color art_colors[i % art_colors.size]
      pdf.fill_rounded_rectangle [lx, legend_y + 7], 10, 7, 1.5
      pdf.fill_color C[:gray]
      pdf.font('Geist Pixel Square', size: 6.5) do
        pdf.draw_text truncate(art[:article_number], 22), at: [lx + 13, legend_y + 1]
      end
    end

    pdf.move_down total_h + 40
  rescue StandardError => e
    Rails.logger.error("Error drawing horizontal policy chart: #{e.message}")
    pdf.move_down 40
  end

  def draw_bar_chart(data:, height:, y:, color: C[:primary])
    chart_style = {
      axes:        { color: C[:white], width: 0.5 },
      bars:        { width_ratio: 0.7, offset_ratio: 0.15, radius: 2, positive_color: color, negative_color: C[:danger] },
      labels:      { font: 'Geist Pixel Square', size: 5.5, color: C[:gray_light], truncate: 4 },
      empty_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:gray], message: 'Dados não disponíveis para o período' },
      error_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:gray], message: 'Erro ao renderizar gráfico' }
    }

    if data.empty?
      pdf.fill_color chart_style[:empty_state][:color]
      pdf.font(chart_style[:empty_state][:font], size: chart_style[:empty_state][:size], style: :italic) do
        pdf.text_box chart_style[:empty_state][:message], at: [0, y - 20], width: CONTENT_W, align: :center
      end
      return
    end

    values  = data.map { |_, v| v.to_f }
    max_val = values.max.nonzero? || 1.0
    chart_y = y - 8
    slot_w  = (CONTENT_W - 40) / [data.size + 1, 1].max.to_f  # ← +1 para a coluna Total

    pdf.stroke_color chart_style[:axes][:color]
    pdf.line_width chart_style[:axes][:width]
    pdf.stroke_horizontal_line 0, CONTENT_W, at: chart_y - height

    data.each_with_index do |(label, val), i|
      val        = val.to_f
      bar_height = (val.abs / max_val * (height - 10)).round(1)
      x          = i * slot_w + slot_w * chart_style[:bars][:offset_ratio]
      w          = slot_w * chart_style[:bars][:width_ratio]
      baseline_y = chart_y - height
      bar_color  = val >= 0 ? chart_style[:bars][:positive_color] : chart_style[:bars][:negative_color]

      pdf.fill_color bar_color
      radius = [chart_style[:bars][:radius], bar_height / 2.0].min
      pdf.fill_rounded_rectangle [x, baseline_y + bar_height], w, bar_height, radius

      if val != 0
        val_label = val >= 1000 || val <= -1000 ? fmt_cur(val) : fmt_pct(val)
        pdf.fill_color chart_style[:labels][:color]
        pdf.font(chart_style[:labels][:font], size: 5) do
          lw = pdf.width_of(val_label)
          lx = [x + (w - lw) / 2.0, 0].max
          ly = baseline_y + bar_height + 2
          pdf.draw_text val_label, at: [lx, ly]
        end
      end

      pdf.fill_color chart_style[:labels][:color]
      pdf.font(chart_style[:labels][:font], size: chart_style[:labels][:size]) do
        pdf.draw_text label.to_s[0..chart_style[:labels][:truncate]], at: [x, baseline_y - 9]
      end
    end

    # ── Coluna Total ──────────────────────────────────────────────────────────
    total_val  = values.sum
    baseline_y = chart_y - height
    bar_height = (total_val.abs / max_val * (height - 10)).round(1)
    x          = data.size * slot_w + slot_w * chart_style[:bars][:offset_ratio]
    w          = slot_w * chart_style[:bars][:width_ratio]
    bar_color  = total_val >= 0 ? C[:primary] : C[:danger]

    pdf.fill_color bar_color
    radius = [chart_style[:bars][:radius], bar_height / 2.0].min
    pdf.fill_rounded_rectangle [x, baseline_y + bar_height], w, bar_height, radius

    pdf.fill_color chart_style[:labels][:color]
    pdf.font(chart_style[:labels][:font], size: 5) do
      lbl = fmt_cur(total_val)
      lw  = pdf.width_of(lbl)
      pdf.draw_text lbl, at: [[x + (w - lw) / 2.0, 0].max, baseline_y + bar_height + 2]
    end

    pdf.font(chart_style[:labels][:font], size: chart_style[:labels][:size]) do
      pdf.draw_text 'Total', at: [x, baseline_y - 9]
    end

  rescue StandardError => e
    Rails.logger.error("Error drawing bar chart: #{e.message}")
  end

  # Desenha um gráfico do tipo Waterfall (cascata) no PDF.
  #
  # O gráfico representa a evolução acumulada de fluxos financeiros ao longo
  # de períodos, onde cada barra parte do acumulado anterior.
  #
  # @param flows [Array<Hash>] coleção de hashes com:
  #   - :period [Date, String] identificador do período
  #   - :applications [Numeric] aportes do período
  #   - :redemptions [Numeric] resgates do período
  #
  # @param height [Numeric] altura total reservada para o gráfico (em pontos)
  # @param y [Numeric] coordenada Y superior onde o gráfico começa
  #
  # Efeitos colaterais:
  # - Desenha linhas, retângulos e textos no objeto `pdf`
  # - Altera temporariamente cores, largura de linha, fonte e estilo de traço
  # - Não altera dados externos, apenas estado visual do documento
  #
  def draw_waterfall_chart(flows:, height:, y:)
    # Interrompe a execução se não houver dados
    # Não altera o PDF neste caso.
    return if flows.empty?

    # Calcula o valor líquido (aplicações - resgates) por período.
    # Não altera o PDF — apenas preparação de dados.
    net_values = flows.map { |f| (f[:applications] - f[:redemptions]).to_f }

    # Soma total acumulada.
    total_net  = net_values.sum

    # ─────────────────────────────────────────────────────────────
    # Construção do acumulado progressivo (running total)
    # ─────────────────────────────────────────────────────────────
    #
    # running: controla o valor acumulado antes e depois de cada barra.
    # segments: estrutura intermediária com:
    #   :base    → valor acumulado antes da barra
    #   :end_val → valor acumulado após aplicar o período
    #
    running = 0.0
    segments = flows.each_with_index.map do |f, i|
      net   = net_values[i]
      base  = running
      running += net

      { period: f[:period], net: net, base: base, end_val: running }
    end

    # ─────────────────────────────────────────────────────────────
    # Normalização da escala vertical
    # ─────────────────────────────────────────────────────────────
    #
    # Determina os limites mínimo e máximo considerando:
    # - todos os acumulados
    # - o zero
    # - o total final
    #
    # Isso garante que o gráfico sempre inclua a linha zero.
    #
    all_vals = segments.flat_map { |s| [s[:base], s[:end_val]] } + [0, total_net]
    y_min    = [all_vals.min, 0].min
    y_max    = [all_vals.max, 0].max
    y_range  = (y_max - y_min).nonzero? || 1.0

    # Define área utilizável do gráfico.
    usable_h = height - 18
    chart_y  = y - 8
    baseline = chart_y - height

    # Define largura de cada coluna.
    n      = segments.size + 1
    slot_w = (CONTENT_W - 10) / [n, 1].max.to_f

    # Converte valor financeiro para coordenada Y no PDF.
    # Não altera estado — apenas função auxiliar.
    to_px = ->(val) { baseline + ((val - y_min) / y_range * usable_h) }

    # ─────────────────────────────────────────────────────────────
    # Desenho das linhas estruturais
    # ─────────────────────────────────────────────────────────────

    # Linha horizontal no zero financeiro.
    pdf.stroke_color C[:border]
    pdf.line_width 0.5
    pdf.stroke_horizontal_line 0, CONTENT_W, at: to_px.call(0)

    # Linha base inferior do gráfico.
    pdf.stroke_color C[:border]
    pdf.line_width 0.5
    pdf.stroke_horizontal_line 0, CONTENT_W, at: baseline

    # ─────────────────────────────────────────────────────────────
    # Desenho das barras intermediárias
    # ─────────────────────────────────────────────────────────────
    segments.each_with_index do |seg, i|
      net = seg[:net]

      # Define posição horizontal e largura da barra.
      x = i * slot_w + slot_w * 0.08
      w = slot_w * 0.84

      # Calcula altura baseada na diferença entre base e acumulado final.
      y_bottom = to_px.call([seg[:base], seg[:end_val]].min)
      y_top    = to_px.call([seg[:base], seg[:end_val]].max)
      bh       = [y_top - y_bottom, 1].max

      # Define cor conforme sinal do valor.
      # Altera estado visual do PDF (fill_color).
      bar_color = net >= 0 ? C[:success] : C[:danger]
      pdf.fill_color bar_color

      # Desenha retângulo arredondado representando a variação.
      radius = [2, bh / 2.0, w / 2.0].min
      pdf.fill_rounded_rectangle [x, y_bottom + bh], w, bh, radius

      # Conector horizontal até próxima barra.
      # Altera temporariamente estilo de traço.
      if i < segments.size - 1
        connector_y = to_px.call(seg[:end_val])
        next_x      = (i + 1) * slot_w

        pdf.stroke_color C[:muted]
        pdf.line_width 0.4
        pdf.dash(2, space: 2)
        pdf.stroke_horizontal_line x + w, next_x + slot_w * 0.08, at: connector_y
        pdf.undash
      end

      # Valor numérico acima (positivo) ou abaixo (negativo).
      pdf.fill_color C[:body]
      pdf.font('Geist Pixel Square', size: 4) do
        val_label = fmt_cur(net)
        lw = pdf.width_of(val_label)
        lx = [x + (w - lw) / 2.0, 0].max
        ly = net >= 0 ? y_bottom + bh + 2 : y_bottom - 8
        pdf.draw_text val_label, at: [lx, ly]
      end

      # Label abreviado do período abaixo da linha base.
      pdf.fill_color C[:muted]
      pdf.font('Geist Pixel Square', size: 4) do
        ml  = short_month(seg[:period])[0..2]
        mlw = pdf.width_of(ml)
        pdf.draw_text ml, at: [x + (w - mlw) / 2.0, baseline - 9]
      end
    end

    # ─────────────────────────────────────────────────────────────
    # Coluna final de Total
    # ─────────────────────────────────────────────────────────────
    #
    # Diferente das anteriores:
    # - Parte sempre do zero
    # - Mostra o acumulado total
    #
    x = segments.size * slot_w + slot_w * 0.08
    w = slot_w * 0.84

    y_bottom = to_px.call([0, total_net].min)
    y_top    = to_px.call([0, total_net].max)
    bh       = [y_top - y_bottom, 1].max

    pdf.fill_color C[:primary]
    radius = [2, bh / 2.0, w / 2.0].min
    pdf.fill_rounded_rectangle [x, y_bottom + bh], w, bh, radius

    # Valor do total.
    pdf.fill_color C[:body]
    pdf.font('Geist Pixel Square', size: 4) do
      val_label = fmt_cur(total_net)
      lw = pdf.width_of(val_label)
      lx = [x + (w - lw) / 2.0, 0].max
      ly = total_net >= 0 ? y_bottom + bh + 2 : y_bottom - 5
      pdf.draw_text val_label, at: [lx, ly]
    end

    # Label fixo "Total".
    pdf.fill_color C[:muted]
    pdf.font('Geist Pixel Square', size: 4) do
      tl  = 'Total'
      tlw = pdf.width_of(tl)
      pdf.draw_text tl, at: [x + (w - tlw) / 2.0, baseline - 9]
    end

    # ─────────────────────────────────────────────────────────────
    # Legenda
    # ─────────────────────────────────────────────────────────────
    #
    # Desenha caixas coloridas + texto explicativo.
    # Altera fill_color e fonte para cada item.
    #
    [[C[:success], 'Aumentar'],
     [C[:danger],  'Diminuir'],
     [C[:primary], 'Total']].each_with_index do |(color, lbl), i|

      lx = i * 85
      ly = chart_y + 4

      pdf.fill_color color
      pdf.fill_rounded_rectangle [lx, ly + 7], 10, 7, 1.5

      pdf.fill_color C[:gray]
      pdf.font('Geist Pixel Square', size: 7) do
        pdf.draw_text lbl, at: [lx + 13, ly + 1]
      end
    end

  rescue StandardError => e
    # Registra erro sem interromper geração completa do relatório.
    Rails.logger.error("Error drawing waterfall chart: #{e.message}")
  end

  def draw_grouped_bar_chart(data:, labels:, colors:, height:, y:)
    chart_style = {
      axes:        { color: C[:white], width: 0.5 },
      bars:        { width_ratio: 0.9, radius: 2, spacing: 8 },
      labels:      { font: 'Geist Pixel Square', size: 5.5, color: C[:muted], truncate: 4 },
      legend:      { font: 'Geist Pixel Square', size: 7, text_color: C[:gray], box_width: 10, box_height: 7, radius: 1.5, spacing_x: 80, offset_from_right: 160 },
      empty_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:gray], message: 'Dados não disponíveis para o período' },
      error_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:gray], message: 'Erro ao renderizar gráfico' }
    }

    if data.empty?
      pdf.fill_color chart_style[:empty_state][:color]
      pdf.font(chart_style[:empty_state][:font], size: chart_style[:empty_state][:size], style: :italic) do
        pdf.text_box chart_style[:empty_state][:message], at: [0, y - 20], width: CONTENT_W, align: :center
      end
      return
    end

    values  = data.flat_map { |_, a, b| [a, b] }.map(&:to_f)
    max_val = values.max.nonzero? || 1.0
    group_w = (CONTENT_W - 20) / [data.size + 1, 1].max.to_f  # ← +1 para o Total
    chart_y = y - 8

    pdf.stroke_color chart_style[:axes][:color]
    pdf.line_width chart_style[:axes][:width]
    pdf.stroke_horizontal_line 0, CONTENT_W, at: chart_y - height

    # ── Barras por grupo ──────────────────────────────────────────────────────
    data.each_with_index do |(label, v1, v2), i|
      x    = i * group_w + 4
      bw   = (group_w - chart_style[:bars][:spacing]) / 2.0
      base = chart_y - height

      [v1, v2].each_with_index do |val, j|
        val        = val.to_f
        bar_height = (val.abs / max_val * (height - 10)).round(1)
        pdf.fill_color colors[j]
        bar_x  = x + j * bw
        bar_w  = bw * chart_style[:bars][:width_ratio]
        radius = [chart_style[:bars][:radius], bar_height / 2.0, bar_w / 2.0].min
        pdf.fill_rounded_rectangle [bar_x, base + bar_height], bar_w, bar_height, radius

        if val != 0
          val_label = val >= 1000 || val <= -1000 ? fmt_cur(val) : fmt_pct(val)
          pdf.fill_color chart_style[:labels][:color]
          pdf.font(chart_style[:labels][:font], size: 5) do
            lw = pdf.width_of(val_label)
            lx = [bar_x + (bar_w - lw) / 2.0, 0].max
            ly = base + bar_height + 2
            pdf.draw_text val_label, at: [lx, ly]
          end
        end
      end

      pdf.fill_color chart_style[:labels][:color]
      pdf.font(chart_style[:labels][:font], size: chart_style[:labels][:size]) do
        pdf.draw_text label.to_s[0..chart_style[:labels][:truncate]], at: [x, base - 9]
      end
    end

    # ── Coluna Total ──────────────────────────────────────────────────────────
    totals = [
      data.sum { |_, v1, _| v1.to_f },
      data.sum { |_, _, v2| v2.to_f }
    ]

    x    = data.size * group_w + 4
    bw   = (group_w - chart_style[:bars][:spacing]) / 2.0
    base = chart_y - height

    totals.each_with_index do |val, j|
      bar_height = (val.abs / max_val * (height - 10)).round(1)
      pdf.fill_color colors[j]
      bar_x  = x + j * bw
      bar_w  = bw * chart_style[:bars][:width_ratio]
      radius = [chart_style[:bars][:radius], bar_height / 2.0, bar_w / 2.0].min
      pdf.fill_rounded_rectangle [bar_x, base + bar_height], bar_w, bar_height, radius

      if val != 0
        val_label = val >= 1000 || val <= -1000 ? fmt_cur(val) : fmt_pct(val)
        pdf.fill_color chart_style[:labels][:color]
        pdf.font(chart_style[:labels][:font], size: 5) do
          lw = pdf.width_of(val_label)
          pdf.draw_text val_label, at: [[bar_x + (bar_w - lw) / 2.0, 0].max, base + bar_height + 2]
        end
      end
    end

    pdf.fill_color chart_style[:labels][:color]
    pdf.font(chart_style[:labels][:font], size: chart_style[:labels][:size]) do
      pdf.draw_text 'Total', at: [x, base - 9]
    end

    # ── Legenda ───────────────────────────────────────────────────────────────
    labels.each_with_index do |lbl, i|
      lx = CONTENT_W - chart_style[:legend][:offset_from_right] + i * chart_style[:legend][:spacing_x]
      ly = chart_y + 2
      pdf.fill_color colors[i]
      pdf.fill_rounded_rectangle [lx, ly + chart_style[:legend][:box_height]], chart_style[:legend][:box_width], chart_style[:legend][:box_height], chart_style[:legend][:radius]
      pdf.fill_color chart_style[:legend][:text_color]
      pdf.font(chart_style[:legend][:font], size: chart_style[:legend][:size]) { pdf.draw_text lbl, at: [lx + 13, ly + 1] }
    end

  rescue StandardError => e
    Rails.logger.error("Error drawing grouped bar chart: #{e.message}")
  end

  def draw_line_chart(series:, height:, y:)
    chart_style = {
      axes:        { color: C[:white], width: 1 },
      line:        { width: 1 },
      labels:      { font: 'Geist Pixel Square', size: 5, color: C[:gray_light] },
      legend:      { font: 'Geist Pixel Square', size: 7, text_color: C[:muted], box_width: 12, box_height: 4, radius: 0.5, spacing_x: 80 },
      empty_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:muted], message: 'Dados não disponíveis para o período' },
      error_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:gray], message: 'Erro ao renderizar gráfico' }
    }

    all_vals = series.flat_map { |s| s[:points].map { |p| p[:value].to_f } }

    if all_vals.empty? || series.first[:points].empty?
      pdf.fill_color chart_style[:empty_state][:color]
      pdf.font(chart_style[:empty_state][:font], size: chart_style[:empty_state][:size]) do
        pdf.text_box chart_style[:empty_state][:message], at: [0, y - 20], width: CONTENT_W, align: :center
      end
      return
    end

    min_val  = [all_vals.min.to_f, 0.0].min
    max_val  = all_vals.max.to_f
    range    = (max_val - min_val).nonzero? || 1.0
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
        yy = chart_y - height + ((pt[:value].to_f - min_val) / range * (height - 12))
        [x, yy]
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
        pdf.draw_text pt[:label].to_s[0..2], at: [x - 6, chart_y - height - 9]
      end
    end

    series.each_with_index do |s, i|
      lx = i * chart_style[:legend][:spacing_x]
      pdf.fill_color s[:color]
      pdf.fill_rounded_rectangle [lx, chart_y + 10], chart_style[:legend][:box_width], chart_style[:legend][:box_height], chart_style[:legend][:radius]
      pdf.fill_color chart_style[:legend][:text_color]
      pdf.font(chart_style[:legend][:font], size: chart_style[:legend][:size]) { pdf.draw_text s[:label], at: [lx + 16, chart_y + 6] }
    end
  rescue StandardError => e
    Rails.logger.error("Error drawing line chart: #{e.message}")
  end

  def draw_allocation_bars(alloc, y:)
    chart_style = {
      bars:        { height: 18, spacing: 20, radius: 2, label_width: 160, value_offset: 4 },
      labels:      { name_font: 'Geist Pixel Square', name_size: 7, name_color: C[:gray_dark], name_truncate: 28,
                     value_font: 'Geist Pixel Square', value_size: 7, value_color: C[:gray] },
      empty_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:gray], message: 'Não há dados de alocação disponíveis' },
      error_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:gray], message: 'Erro ao renderizar alocação' }
    }

    if alloc.empty?
      pdf.fill_color chart_style[:empty_state][:color]
      pdf.font(chart_style[:empty_state][:font], size: chart_style[:empty_state][:size], style: :italic) do
        pdf.text_box chart_style[:empty_state][:message], at: [0, y - 20], width: CONTENT_W, align: :center
      end
      pdf.move_down 40
      return
    end

    max_alloc = alloc.map { |a| a[:allocation].to_f }.max.nonzero? || 1.0

    alloc.first(12).each_with_index do |item, i|
      by      = y - i * chart_style[:bars][:spacing] - 16
      alloc_f = item[:allocation].to_f
      bar_w   = (alloc_f / max_alloc * (CONTENT_W - 200)).round(1)
      color   = C[:chart][i % C[:chart].size]

      pdf.fill_color chart_style[:labels][:name_color]
      pdf.font(chart_style[:labels][:name_font], size: chart_style[:labels][:name_size]) do
        pdf.draw_text truncate(item[:fund_name].to_s, chart_style[:labels][:name_truncate]), at: [0, by + 6]
      end

      pdf.fill_color color
      radius = [chart_style[:bars][:radius], (chart_style[:bars][:height] - 4) / 2.0].min
      pdf.fill_rounded_rectangle [chart_style[:bars][:label_width], by + chart_style[:bars][:height] - 2],
                                 [bar_w, 1].max, chart_style[:bars][:height] - 4, radius

      pdf.fill_color chart_style[:labels][:value_color]
      pdf.font(chart_style[:labels][:value_font], size: chart_style[:labels][:value_size]) do
        pdf.draw_text "#{fmt_num(alloc_f, 2)}%",
                      at: [chart_style[:bars][:label_width] + bar_w + chart_style[:bars][:value_offset], by + 6]
      end

      break if by < 20
    end

    pdf.move_down [alloc.size, 12].min * chart_style[:bars][:spacing] + 10
  rescue StandardError => e
    Rails.logger.error("Error drawing allocation bars: #{e.message}")
    pdf.move_down 40
  end

  def draw_horizontal_bars(data:, color:, y:)
    chart_style = {
      bars:        { height: 18, spacing: 22, radius: 2, label_width: 170, value_offset: 4 },
      labels:      { name_font: 'Geist Pixel Square', name_size: 7, name_color: C[:gray_dark], name_truncate: 26,
                     value_font: 'Geist Pixel Square', value_size: 7, value_color: C[:gray] },
      empty_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:gray], message: 'Dados não disponíveis' },
      error_state: { font: 'Plus Jakarta Sans', size: 9, color: C[:gray], message: 'Erro ao renderizar gráfico' }
    }

    if data.empty?
      pdf.fill_color chart_style[:empty_state][:color]
      pdf.font(chart_style[:empty_state][:font], size: chart_style[:empty_state][:size], style: :italic) do
        pdf.text_box chart_style[:empty_state][:message], at: [0, y - 20], width: CONTENT_W, align: :center
      end
      pdf.move_down 40
      return
    end

    max_val = data.map { |d| d[:value].to_f }.max.nonzero? || 1.0

    data.first(8).each_with_index do |item, i|
      by    = y - i * chart_style[:bars][:spacing] - 16
      bar_w = (item[:value].to_f / max_val * (CONTENT_W - 230)).round(1)

      pdf.fill_color chart_style[:labels][:name_color]
      pdf.font(chart_style[:labels][:name_font], size: chart_style[:labels][:name_size]) do
        pdf.draw_text truncate(item[:label].to_s, chart_style[:labels][:name_truncate]), at: [0, by + 6]
      end

      pdf.fill_color color
      radius = [chart_style[:bars][:radius], (chart_style[:bars][:height] - 4) / 2.0].min
      pdf.fill_rounded_rectangle [chart_style[:bars][:label_width], by + chart_style[:bars][:height] - 2],
                                 [bar_w, 1].max, chart_style[:bars][:height] - 4, radius

      pdf.fill_color chart_style[:labels][:value_color]
      pdf.font(chart_style[:labels][:value_font], size: chart_style[:labels][:value_size]) do
        pdf.draw_text fmt_cur(item[:value]),
                      at: [chart_style[:bars][:label_width] + bar_w + chart_style[:bars][:value_offset], by + 6]
      end

      break if by < 20
    end

    pdf.move_down [data.size, 8].min * chart_style[:bars][:spacing] + 10
  rescue StandardError => e
    Rails.logger.error("Error drawing horizontal bars: #{e.message}")
    pdf.move_down 40
  end

  def draw_donut_chart(data:, cx:, cy:, radius:, hole_ratio: 0.55, legend_x: nil, legend_y: nil, gap_deg: 1.5)
    return if data.empty?

    total = data.sum { |d| d[:value].to_f }
    return if total <= 0

    colors      = C[:chart]
    steps       = 60
    start_angle = 90.0

    # ── Fatias ────────────────────────────────────────────────────────────────────
    data.each_with_index do |item, i|
      pct   = item[:value].to_f / total
      next if pct <= 0

      sweep     = pct * 360.0 - gap_deg
      sweep     = [sweep, 0.1].max
      end_angle = start_angle - sweep
      color     = item[:color] || colors[i % colors.size]

      n_steps = [(pct * steps).ceil, 2].max
      angles  = n_steps.times.map { |j| start_angle - (sweep * j / (n_steps - 1).to_f) }

      points = [[cx, cy]] + angles.map do |a|
        rad = a * Math::PI / 180.0
        [cx + radius * Math.cos(rad), cy + radius * Math.sin(rad)]
      end

      pdf.fill_color color
      pdf.fill_polygon(*points)

      # Label % no meio da fatia (só se >= 4%)
      if pct >= 0.04
        mid_rad = ((start_angle + end_angle) / 2.0) * Math::PI / 180.0
        lr      = radius * 0.73
        lx      = cx + lr * Math.cos(mid_rad)
        ly      = cy + lr * Math.sin(mid_rad)
        pdf.fill_color C[:white]
        pdf.font('Geist Pixel Square', size: 5.5) do
          lbl = "#{fmt_num(pct * 100, 2)}%"
          lw  = pdf.width_of(lbl)
          pdf.draw_text lbl, at: [lx - lw / 2.0, ly - 3]
        end
      end

      start_angle = end_angle - gap_deg
    end

    # ── Buraco central ────────────────────────────────────────────────────────────
    pdf.fill_color C[:white]
    pdf.fill_circle [cx, cy], radius * hole_ratio

    # ── Legenda ───────────────────────────────────────────────────────────────────
    lx     = legend_x || (cx + radius + 16)
    ly     = legend_y || (cy + radius / 2.0)
    line_h = 16

    data.each_with_index do |item, i|
      pct    = item[:value].to_f / total
      color  = item[:color] || colors[i % colors.size]
      iy     = ly - i * line_h

      pdf.fill_color color
      pdf.fill_circle [lx + 5, iy + 4], 4.5

      pdf.fill_color C[:muted]
      pdf.font('Geist Pixel Square', size: 7) do
        pdf.draw_text "#{fmt_num(pct * 100, 2)}%  #{truncate(item[:label].to_s, 20)}", at: [lx + 14, iy]
      end
    end

  rescue StandardError => e
    Rails.logger.error("draw_donut_chart: #{e.message}")
  end

  # Gráfico horizontal mostrando conformidade com a política de investimentos.
  # Para cada artigo normativo: duas barras sobrepostas (Carteira atual + Alvo),
  # com traços opcionais de Mínimo e Máximo.
  def draw_policy_compliance_bars(compliance, y:)
    return if compliance.empty?

    bar_h     = 10
    group_gap = 28   # espaço vertical por artigo
    label_w   = 160  # largura reservada para o nome do artigo
    bar_area  = CONTENT_W - label_w - 50
    colors    = C[:chart]

    # Encontra o maior valor para escalar o eixo X
    all_pcts = compliance.values.flat_map { |v| [v[:current], v[:target], v[:min], v[:max]].compact }
    max_pct  = [all_pcts.max.to_f, 100.0].max

    cur_y = y - 4

    compliance.each_with_index do |(key, v), idx|
      color = colors[idx % colors.size]
      mid_y = cur_y - idx * group_gap

      # ── Barra Carteira Atual ──────────────────────────────────────────────
      cart_w = (v[:current] / max_pct * bar_area).round(1)
      pdf.fill_color C[:danger]
      pdf.fill_rounded_rectangle [label_w, mid_y], [cart_w, 1].max, bar_h, [2, bar_h / 2.0].min
      pdf.fill_color C[:body]
      pdf.font('Geist Pixel Square', size: 6) do
        pdf.draw_text "#{fmt_num(v[:current], 2)}%", at: [label_w + cart_w + 3, mid_y - bar_h + 3]
      end

      # ── Barra Alvo ────────────────────────────────────────────────────────
      if v[:target] > 0
        tgt_w = (v[:target] / max_pct * bar_area).round(1)
        pdf.fill_color color
        pdf.fill_rounded_rectangle [label_w, mid_y - bar_h - 2], [tgt_w, 1].max, bar_h, [2, bar_h / 2.0].min
        pdf.fill_color C[:body]
        pdf.font('Geist Pixel Square', size: 6) do
          pdf.draw_text "#{fmt_num(v[:target], 2)}%", at: [label_w + tgt_w + 3, mid_y - bar_h - 2 - bar_h + 3]
        end
      end

      # ── Traço Mínimo ──────────────────────────────────────────────────────
      if v[:min]
        min_x = label_w + (v[:min] / max_pct * bar_area).round(1)
        pdf.stroke_color C[:muted]
        pdf.line_width 0.6
        pdf.dash(1.5, space: 1.5)
        pdf.stroke_vertical_line mid_y - bar_h * 2 - 4, mid_y + 2, at: min_x
        pdf.undash
        pdf.fill_color C[:muted]
        pdf.font('Geist Pixel Square', size: 5) do
          pdf.draw_text "Mín #{fmt_num(v[:min], 0)}%", at: [min_x - 10, mid_y + 4]
        end
      end

      # ── Traço Máximo ──────────────────────────────────────────────────────
      if v[:max]
        max_x = label_w + (v[:max] / max_pct * bar_area).round(1)
        pdf.stroke_color C[:muted]
        pdf.line_width 0.6
        pdf.dash(1.5, space: 1.5)
        pdf.stroke_vertical_line mid_y - bar_h * 2 - 4, mid_y + 2, at: max_x
        pdf.undash
        pdf.fill_color C[:muted]
        pdf.font('Geist Pixel Square', size: 5) do
          pdf.draw_text "Máx #{fmt_num(v[:max], 0)}%", at: [max_x - 10, mid_y + 4]
        end
      end

      # ── Ícone de conformidade ─────────────────────────────────────────────
      icon_color = v[:within_range] ? C[:success] : C[:danger]
      icon_char  = v[:within_range] ? '●' : '▲'
      pdf.fill_color icon_color
      pdf.font('Geist Pixel Square', size: 7) do
        pdf.draw_text icon_char, at: [CONTENT_W - 12, mid_y - bar_h + 1]
      end

      # ── Nome do artigo ────────────────────────────────────────────────────
      pdf.fill_color C[:gray_dark]
      pdf.font('Geist Pixel Square', size: 6.5) do
        pdf.draw_text truncate(v[:display_name], 28), at: [0, mid_y - bar_h + 1]
      end
    end

    # ── Eixo X com marcações de % ─────────────────────────────────────────────
    bottom_y = y - compliance.size * group_gap - 4
    [0, 25, 50, 75, 100].each do |pct|
      next if pct > max_pct
      tick_x = label_w + (pct / max_pct * bar_area).round(1)
      pdf.stroke_color C[:border]
      pdf.line_width 0.4
      pdf.stroke_vertical_line bottom_y, y + 2, at: tick_x
      pdf.fill_color C[:muted]
      pdf.font('Geist Pixel Square', size: 5) do
        pdf.draw_text "#{pct}%", at: [tick_x - 5, bottom_y - 9]
      end
    end

    # ── Legenda ────────────────────────────────────────────────────────────────
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

  def draw_comparison_bars(items, y:)
    chart_style = {
      bars:   { height: 18, spacing: 26, radius: 2, label_width: 80, value_offset: 6 },
      labels: { name_font: 'Geist Pixel Square', name_size: 8, name_color: C[:muted],
                value_font: 'Geist Pixel Square', value_size: 8, value_color: C[:muted] }
    }

    max_val = items.map { |i| i[:value].to_f }.max.nonzero? || 1.0

    items.each_with_index do |item, i|
      by    = y - i * chart_style[:bars][:spacing] - 16
      bar_w = (item[:value].to_f.abs / max_val * (CONTENT_W - 120)).round(1)

      pdf.fill_color chart_style[:labels][:name_color]
      pdf.font(chart_style[:labels][:name_font], size: chart_style[:labels][:name_size]) do
        pdf.draw_text item[:label].to_s, at: [0, by + 6]
      end

      pdf.fill_color item[:color]
      radius = [chart_style[:bars][:radius], (chart_style[:bars][:height] - 4) / 2.0].min
      pdf.fill_rounded_rectangle [chart_style[:bars][:label_width], by + chart_style[:bars][:height] - 2],
                                 [bar_w, 1].max, chart_style[:bars][:height] - 4, radius

      pdf.fill_color chart_style[:labels][:value_color]
      pdf.font(chart_style[:labels][:value_font], size: chart_style[:labels][:value_size]) do
        pdf.draw_text fmt_pct(item[:value]),
                      at: [chart_style[:bars][:label_width] + bar_w + chart_style[:bars][:value_offset], by + 6]
      end
    end

    pdf.move_down items.size * chart_style[:bars][:spacing] + 10
  end

  # ─── TABLE ───────────────────────────────────────────────────────────────────

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
      pdf.font('Plus Jakarta Sans', size: 7, style: :italic) do
        pdf.text_box 'Não há dados disponíveis', at: [0, pdf.cursor - 20], width: CONTENT_W, align: :center
      end
      pdf.move_down 40
      return
    end

    sanitized_rows = rows.map do |row|
      row.map { |cell| cell.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?') }
    end

    colors = { body: C[:body], bg_light: C[:bg_light], white: C[:white], border: C[:border], primary: C[:primary] }

    base_opts = {
      header: true,
      width: CONTENT_W,
      cell_style: {
        font: 'Plus Jakarta Sans',
        size: 7,
        padding: [6, 8],
        borders: %i[top bottom],
        border_color: colors[:border],
        border_width: 1,
        inline_format: true,
        overflow: :shrink_to_fit,
        min_font_size: 7
      }
    }

    base_opts[:column_widths] = col_widths if col_widths

    build_table = lambda do |options|
      pdf.table(sanitized_rows, options) do |t|
        t.row(0).tap do |row|
          row.text_color       = colors[:body]
          row.background_color = colors[:bg_light]
          row.borders          = [:top, :bottom]
        end

        (1...sanitized_rows.size).each do |row_idx|
          t.row(row_idx).background_color = colors[:white]
          sanitized_rows[row_idx].each_with_index do |cell_value, col_idx|
            cell = t.cells[row_idx, col_idx]
            numeric_value   = extract_numeric_value(cell_value)
            cell.font       = 'Geist Mono'
            cell.text_color = color_for_value(numeric_value)
          end
        end

        if last_row_bold && sanitized_rows.size > 1
          last_idx = sanitized_rows.size - 1
          t.row(last_idx).tap do |row|
            row.background_color = colors[:bg_light]
            row.borders          = [:top, :bottom]
            row.border_color     = colors[:body]
          end
          sanitized_rows[last_idx].each_with_index do |cell_value, col_idx|
            cell = t.cells[last_idx, col_idx]
            if numeric_cell?(cell_value)
              cell.font       = 'Geist Pixel Square'
              cell.text_color = color_for_value(extract_numeric_value(cell_value))
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

  # ─── PAGE LAYOUT ─────────────────────────────────────────────────────────────

  def page_header(title)
    pdf.pad 10 do
      pdf.font('Source Serif 4', size: 24) do
        text = title

        # Calcula altura real do texto considerando quebra de linha
        text_height = pdf.height_of(text, width: CONTENT_W - 140)

        # Desenha o texto
        pdf.text_box text,
                     width: CONTENT_W - 140,
                     height: text_height,
                     overflow: :expand

        # Move o cursor exatamente o necessário
        pdf.move_down text_height
      end
    end

    # Linha principal
    pdf.line_width = 1
    pdf.stroke_color C[:secondary]
    pdf.stroke_horizontal_rule

    pdf.move_down 6

    # Linha inferior
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
        pdf.font('Geist', size: 14) do
          pdf.draw_text title.to_s.upcase, at: [0, start_y]
        end

        if info
          pdf.fill_color C[:muted]
          pdf.font('Geist Pixel Square', size: 8) do
            info_text  = info.to_s.upcase
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

  # ─── SERIES BUILDERS ─────────────────────────────────────────────────────────

  def build_monthly_returns_series
    data[:monthly_history].map do |m|
      perfs       = @portfolio.performance_histories
                              .where(period: m[:period])
                              .includes(fund_investment: :investment_fund)
      alloc_total = perfs.sum { |p| p.fund_investment.percentage_allocation.to_f }
      weighted    = perfs.sum { |p| p.monthly_return.to_f * p.fund_investment.percentage_allocation.to_f }
      ret         = alloc_total > 0 ? (weighted / alloc_total) : 0.0
      { period: m[:period].beginning_of_month, value: ret, label: short_month(m[:period]) }
    end
  end

  def build_meta_series
    # Explanation:: Recalcula a META mês a mês: juros anuais do portfolio dividido
    #               por 12 (parcela mensal) somado ao IPCA histórico daquele mês.
    monthly_rate = @portfolio.annual_interest_rate.to_f

    data[:monthly_history].map do |m|
      per      = m[:period].beginning_of_month
      ipca_val = meta_monthly_series[per][:ipca]
      val      = monthly_rate + ipca_val
      { period: per, value: val, label: short_month(m[:period]) }
    end
  end

  # ─── HELPERS ─────────────────────────────────────────────────────────────────

  # == draw_compliance_legend
  #
  # Desenha a legenda de enquadramento normativo (Art. 7º, Inciso III "a" e Art. 7º, Inciso I "b")
  # conforme exibida nas imagens de referência dos gráficos de tipo de ativo.
  # Usada nas páginas de Patrimônio por Índice e Patrimônio por Tipo de Ativo.
  #
  def draw_compliance_legend
    legend_y = pdf.cursor - 4

    pdf.fill_color C[:muted]
    pdf.font('Plus Jakarta Sans', size: 7) do
      pdf.draw_text 'Enquadramento 4.963/21', at: [0, legend_y]
    end

    items = [
      { color: C[:primary],   label: 'Item I' },
      { color: C[:secondary], label: 'Item II' }
    ]

    x_offset = 120
    items.each do |item|
      pdf.fill_color item[:color]
      pdf.fill_circle [x_offset + 4, legend_y + 3], 3.5

      pdf.fill_color C[:muted]
      pdf.font('Plus Jakarta Sans', size: 7) do
        pdf.draw_text item[:label], at: [x_offset + 12, legend_y]
      end

      x_offset += pdf.width_of(item[:label]) + 30
    end

    pdf.move_down 14
  end

  def monthly_apps_for(fi)
    fi.applications
      .where(cotization_date: @reference_date.beginning_of_month..@reference_date)
      .sum(:financial_value).to_f
  rescue StandardError
    0.0
  end

  # == meta_monthly_series
  #
  # @category Helper
  #
  # Explanation:: Retorna um Hash memoizado { Date => { ipca: Float, meta: Float } }
  #               pré-calculado para os 12 meses do relatório.
  #               META mensal = annual_interest_rate / 12 + IPCA do mês.
  #               Evita N+1 queries ao percorrer meses nos gráficos e tabelas.
  #
  def meta_monthly_series
    @meta_monthly_series ||= begin
                               ipca_index   = EconomicIndex.find_by(abbreviation: 'IPCA')
                               monthly_rate = @portfolio.annual_interest_rate.to_f
                               start_date   = (@reference_date - 11.months).beginning_of_month

                               # Carrega todos os registros IPCA do período em uma única query
                               ipca_by_month = if ipca_index
                                                 ipca_index.economic_index_histories
                                                           .where(date: start_date..@reference_date.end_of_month)
                                                           .index_by { |h| h.date.beginning_of_month }
                                               else
                                                 {}
                                               end

                               Hash.new do |h, date|
                                 key      = date.beginning_of_month
                                 ipca_val = ipca_by_month[key]&.value.to_f || 0.0
                                 h[key]   = { ipca: ipca_val, meta: monthly_rate + ipca_val }
                               end
                             end
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
    I18n.l(@reference_date, format: '%B de %Y').capitalize
  rescue StandardError
    @reference_date.strftime('%B de %Y')
  end
end