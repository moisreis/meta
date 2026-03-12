# =============================================================
# Configuration & Dependencies
# =============================================================

# FIX: Renamed from ALLOWED_SORT_COLUMNS / ALLOWED_DIRECTIONS to avoid constant
# redefinition warnings at boot time. Multiple controllers used the same generic
# names, causing Ruby to emit "already initialized constant" warnings and, in
# some load-order scenarios, silently clobbering the other controller's whitelist.
PORTFOLIOS_ALLOWED_SORT_COLUMNS = %w[id name created_at updated_at].freeze
PORTFOLIOS_ALLOWED_DIRECTIONS = %w[asc desc].freeze

# === portfolios_controller.rb
#
# Description:: Manages the lifecycle of investment portfolios within the system.
#
class PortfoliosController < ApplicationController

  include PdfExportable
  include MonthlyReportable

  before_action :authenticate_user!

  before_action :set_portfolio, only: %i[show edit update destroy monthly_report run_calculations calculation_progress]

  before_action :authorize_portfolio_management!, only: %i[edit update destroy run_calculations monthly_report calculation_progress]

  # =============================================================
  # Error handling
  # =============================================================

  rescue_from ActiveRecord::RecordNotFound do |e|
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: "Carteira não encontrada." }
      format.json { render json: { error: e.message }, status: :not_found }
    end
  end

  rescue_from CanCan::AccessDenied do |e|
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: e.message }
      format.json { render json: { error: e.message }, status: :forbidden }
    end
  end

  rescue_from StandardError do |e|
    Rails.logger.error("[PortfoliosController] Unhandled error: #{e.class} — #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: "Ocorreu um erro inesperado." }
      format.json { render json: { error: "Internal server error" }, status: :internal_server_error }
    end
  end

  # =============================================================
  # Public Methods
  # =============================================================

  def index
    base_scope = current_user.admin? ? Portfolio.all : Portfolio.for_user(current_user)

    @q = base_scope.includes(:user, :user_portfolio_permissions).ransack(params[:q])
    filtered = @q.result(distinct: true)

    @total_items = filtered.count

    sort = PORTFOLIOS_ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "id"
    direction = PORTFOLIOS_ALLOWED_DIRECTIONS.include?(params[:direction]) ? params[:direction] : "asc"

    @portfolios = @models = filtered.order("portfolios.#{sort} #{direction}").page(params[:page]).per(14)

    respond_to { |f| f.html }
  end

  def show
    @new_application = Application.new
    @new_redemption = Redemption.new

    @reference_date = params[:reference_date].present? ? Date.parse(params[:reference_date]) : Date.current

    fund_investments = @portfolio.fund_investments
                                 .includes(:investment_fund, :applications, :redemptions)

    @allocation_data = fund_investments.map do |fi|
      [fi.investment_fund.fund_name, fi.percentage_allocation || 0]
    end

    @institution_distribution = fund_investments
                                  .group_by { |fi| fi.investment_fund.administrator_name }
                                  .map { |admin, investments| [admin, investments.sum { |fi| fi.percentage_allocation || 0 }] }

    @monthly_flows = calculate_monthly_flows(@portfolio)

    @reference_period = Date.current.end_of_month

    @recent_performance = @portfolio.performance_histories
                                    .where(period: @reference_period)
                                    .includes(fund_investment: :investment_fund)

    if @recent_performance.empty?
      latest_period = @portfolio.performance_histories.maximum(:period)
      if latest_period
        @reference_period = latest_period
        @recent_performance = @portfolio.performance_histories
                                        .where(period: @reference_period)
                                        .includes(fund_investment: :investment_fund)
      end
    end

    @recent_performance = @recent_performance.order("monthly_return DESC")
    @portfolio_yearly_return = @portfolio.portfolio_yearly_return_percentage(@reference_period)

    @equity_evolution = @portfolio.value_timeline(12)

    @monthly_earnings_history = @portfolio.monthly_earnings_history

    @total_earnings = BigDecimal("0")
    @portfolio_return = BigDecimal("0")
    @portfolio_12m_return = BigDecimal("0")

    if @recent_performance.any?
      effective_initial_balance = ->(perf) do
        if perf.initial_balance&.positive?
          perf.initial_balance
        elsif perf.monthly_return&.nonzero? && perf.earnings
          (perf.earnings / (perf.monthly_return / BigDecimal("100"))).abs
        else
          BigDecimal("0")
        end
      end

      total_initial_balance = @recent_performance.sum { |p| effective_initial_balance.call(p) }
      @total_earnings = @recent_performance.sum(:earnings)

      if total_initial_balance > 0
        @portfolio_return = (@total_earnings / total_initial_balance) * 100

        weighted_12m = BigDecimal("0")
        @recent_performance.each do |perf|
          weight = effective_initial_balance.call(perf) / total_initial_balance
          weighted_12m += (perf.last_12_months_return || 0) * weight
        end

        @portfolio_12m_return = weighted_12m
      end
    end
  end

  def new
    @portfolio = Portfolio.new
  end

  def edit; end

  def create
    @portfolio = Portfolio.new(portfolio_params.except(:shared_user_id))

    if @portfolio.save
      grant_permission_if_present
      redirect_to @portfolio, notice: "Carteira criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @portfolio.update(portfolio_params.except(:shared_user_id))
      grant_permission_if_present
      redirect_to @portfolio, notice: "Carteira atualizada com sucesso.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @portfolio.destroy!
    redirect_to portfolios_path, notice: "Carteira deletada com sucesso.", status: :see_other
  end

  def run_calculations
    selected_month = if params[:month].present?
                       Date.strptime(params[:month], "%Y-%m")
                     else
                       Date.yesterday.prev_month.beginning_of_month
                     end

    # The job does `reference_date = target_date.prev_month` internally,
    # so we shift forward one month to land on the intended period.
    target_date = selected_month.next_month.end_of_month

    PerformanceCalculationJob.perform_later(target_date: target_date)

    redirect_to portfolio_path(@portfolio),
                notice: "Cálculo de #{I18n.l(selected_month, format: '%B/%Y')} iniciado em segundo plano!"
  end

  def monthly_report
    day = params[:day].presence&.to_i
    month = params[:month].presence&.to_i
    year = params[:year].presence&.to_i

    reference_date = if month && year
                       if day
                         begin
                           Date.new(year, month, day)
                         rescue ArgumentError
                           Date.new(year, month, -1)
                         end
                       else
                         Date.new(year, month, -1)
                       end
                     else
                       Date.current.end_of_month
                     end

    begin
      generator = PortfolioMonthlyReportGenerator.new(@portfolio, reference_date)
      pdf_bytes = generator.generate
      send_data pdf_bytes,
                filename: "relatorio_#{@portfolio.id}_#{reference_date.strftime('%Y-%m-%d')}.pdf",
                type: "application/pdf",
                disposition: "inline"
    rescue => e
      Rails.logger.error("[monthly_report] #{e.class}: #{e.message}\n#{e.backtrace.first(10).join("\n")}")
      raise
    end
  end

  # Trecho a adicionar / adaptar em app/controllers/portfolios_controller.rb
  #
  # ─── Ação que executa os cálculos ────────────────────────────────────────────

  def run_calculations
    month = params[:month] # "2025-01"
    date = Date.parse("#{month}-01").end_of_month

    # Chave única por portfolio + mês (evita colisão entre usuários)
    @progress_key = "calc_progress_#{@portfolio.id}_#{month}"

    # Garante que o cache começa zerado
    Rails.cache.write(@progress_key, { percent: 0, step: "Iniciando…", done: false }, expires_in: 10.minutes)

    # Helper interno para atualizar progresso de qualquer ponto do service
    progress = ->(percent, step) do
      Rails.cache.write(@progress_key, { percent:, step:, done: percent >= 100 }, expires_in: 10.minutes)
    end

    # ── Passo 1 ── Cotas e valuations ──────────────────────────
    progress.call(10, "Buscando cotas do período…")
    fund_investments = @portfolio.fund_investments.includes(:investment_fund, :applications, :redemptions)

    # ── Passo 2 ── Calcular valor de mercado ───────────────────
    progress.call(30, "Calculando valor de mercado…")
    fund_investments.each do |fi|
      fi.current_market_value(date) # chama o método existente (força memoização/cálculo)
    end

    # ── Passo 3 ── Registrar performance histories ─────────────
    progress.call(55, "Registrando performance dos fundos…")
    fund_investments.each do |fi|
      # Adapte aqui para o seu service real de gravação de PerformanceHistory
      safe_date = [date, Date.current].min   # nunca ultrapassa hoje

      PerformanceHistory.find_or_initialize_by(
        fund_investment: fi,
        portfolio:       @portfolio,          # ← campo obrigatório
        period:          safe_date
      ).tap do |ph|
        ph.monthly_return = fi.period_return_percentage(safe_date)
        ph.earnings       = fi.total_gain(safe_date)
        ph.save!
      end
    end

    # ── Passo 4 ── Consolidar métricas do portfolio ────────────
    progress.call(80, "Consolidando métricas da carteira…")
    @portfolio.touch # ou qualquer callback de recalculação que você já tenha

    # ── Passo 5 ── Concluído ───────────────────────────────────
    progress.call(100, "Concluído!")

    redirect_to portfolio_path(@portfolio, reference_date: date),
                notice: "Performance calculada com sucesso."
  end

  # ─── Endpoint de polling (GET /portfolios/:id/calculation_progress) ──────────

  def calculation_progress
    month = params[:month] || Date.current.strftime("%Y-%m")
    progress_key = "calc_progress_#{@portfolio.id}_#{month}"
    data = Rails.cache.read(progress_key) || { percent: 0, step: "Aguardando…", done: false }

    render json: data
  end

  # =============================================================
  # Private Methods
  # =============================================================

  private

  # == set_portfolio
  #
  # FIX: Scoped to portfolios accessible by the current user so that an ID
  # belonging to another user raises RecordNotFound instead of exposing the record.
  def set_portfolio
    @portfolio = Portfolio.for_user(current_user).find(params[:id])
  end

  # == authorize_portfolio_management!
  #
  # FIX: Confirms the user has management rights (owner or crud permission) before
  # any mutating action. Raises CanCan::AccessDenied for read-only shared users.
  def authorize_portfolio_management!
    authorize! :manage, @portfolio
  end

  def portfolio_params
    params.require(:portfolio).permit(
      :name,
      :user_id,
      :annual_interest_rate,
      :shared_user_id
    )
  end

  def grant_permission_if_present
    shared_user_id = params.dig(:portfolio, :shared_user_id)
    permission_level = params.dig(:portfolio, :grant_crud_permission) || "read"

    return unless shared_user_id.present?

    UserPortfolioPermission.find_or_create_by!(
      user_id: shared_user_id,
      portfolio_id: @portfolio.id
    ) do |p|
      p.permission_level = permission_level
    end
  end

  def calculate_monthly_flows(portfolio)
    all_months = (1..12).map { |m| Date.new(Date.current.year, m, 1) }

    monthly_data = all_months.map do |month_start|
      month_end = month_start.end_of_month

      applications_sum = Application
                           .joins(:fund_investment)
                           .where(fund_investments: { portfolio_id: portfolio.id })
                           .where(cotization_date: month_start..month_end)
                           .sum(:financial_value)

      redemptions_sum = Redemption
                          .joins(:fund_investment)
                          .where(fund_investments: { portfolio_id: portfolio.id })
                          .where(cotization_date: month_start..month_end)
                          .sum(:redeemed_liquid_value)

      { month: month_start.strftime("%b/%y"), applications: applications_sum, redemptions: redemptions_sum }
    end

    [
      { name: "Aplicações", data: monthly_data.map { |m| [m[:month], m[:applications]] } },
      { name: "Resgates", data: monthly_data.map { |m| [m[:month], m[:redemptions]] } }
    ]
  end

  def pdf_export_title
    "Carteiras"
  end

  def pdf_export_subtitle
    "Lista de carteiras com permissão de visualização"
  end

  def pdf_export_columns
    h = ActionController::Base.helpers

    [
      { header: "Nome", key: :name, width: 150 },
      {
        header: "Proprietário",
        key: ->(portfolio) { portfolio.user == current_user ? "Você" : portfolio.user.full_name },
        width: 120
      },
      {
        header: "Compartilhado com",
        key: ->(portfolio) {
          shared = portfolio.user_portfolio_permissions
          shared.any? ? shared.map { |p| p.user == current_user ? "Você" : p.user.full_name }.join(", ") : "N/A"
        },
        width: 150
      },
      {
        header: "Valor Investido",
        key: ->(portfolio) { h.number_to_currency(portfolio.total_invested_value, unit: "R$ ", separator: ",", delimiter: ".") },
        width: 100
      },
      {
        header: "Cotas",
        key: ->(portfolio) { h.number_with_precision(portfolio.total_quotas_held, precision: 2, separator: ",", delimiter: ".") },
        width: 100
      }
    ]
  end

  def pdf_export_data
    base_scope = current_user.admin? ? Portfolio.all : Portfolio.for_user(current_user)
    @q = base_scope.ransack(params[:q])
    @q.result(distinct: true)
  end

  def pdf_export_metadata
    { "Gerado por" => current_user.full_name }
  end
end
