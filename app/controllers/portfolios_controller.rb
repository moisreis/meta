PORTFOLIOS_ALLOWED_SORT_COLUMNS = %w[id name created_at updated_at].freeze

PORTFOLIOS_ALLOWED_DIRECTIONS = %w[asc desc].freeze

class PortfoliosController < ApplicationController

  include PdfExportable

  include MonthlyReportable

  before_action :authenticate_user!
  before_action :set_portfolio, only: %i[show edit update destroy monthly_report run_calculations calculation_progress]
  before_action :authorize_portfolio_management!, only: %i[edit update destroy run_calculations monthly_report calculation_progress]

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

    @indices_data = @portfolio.fund_investments
                              .joins(:investment_fund)
                              .group("investment_funds.benchmark_index")
                              .sum(:percentage_allocation)
                              .transform_keys { |key| key.presence || "Outros" }

    @normative_data = @portfolio.fund_investments
                                .joins(investment_fund: :normative_articles)
                                .group("normative_articles.article_number")
                                .sum(:percentage_allocation)
                                .transform_keys { |key| key.presence || "Não enquadrado" }

    @monthly_flows = calculate_monthly_flows(@portfolio)

    @reference_period = @reference_date.end_of_month

    @recent_performance = @portfolio.performance_histories
                                    .where(period: @reference_period)
                                    .includes(fund_investment: :investment_fund)

    @portfolio_monthly_twr = @portfolio.portfolio_twr_return_on(
      @reference_date.beginning_of_month - 1.day,
      @reference_date
    )
    @portfolio_yearly_twr = @portfolio.portfolio_twr_return_on(
      @reference_date.beginning_of_year - 1.day,
      @reference_date
    )

    if @recent_performance.empty?
      latest_period = @portfolio.performance_histories.maximum(:period)
      if latest_period
        @reference_period = latest_period
        @recent_performance = @portfolio.performance_histories
                                        .where(period: @reference_period)
                                        .includes(fund_investment: :investment_fund)
      end
    end

    @performance_by_fund = @recent_performance.index_by(&:fund_investment_id)

    @recent_performance = @recent_performance.order("monthly_return DESC")
    @portfolio_yearly_return = @portfolio.portfolio_yearly_return_percentage(@reference_period)

    @equity_evolution = @portfolio.value_timeline(12)
    @monthly_earnings_history = @portfolio.monthly_earnings_history

    @total_market_value = fund_investments.sum { |fi| fi.current_market_value_on(@reference_date) }

    @total_earnings = BigDecimal("0")
    @portfolio_return = BigDecimal("0")
    @portfolio_12m_return = BigDecimal("0")

    if @recent_performance.any?
      active_performance = @recent_performance.select do |perf|
        fi = perf.fund_investment
        fi.current_market_value_on(@reference_period) > 0 ||
          fi.applications.where("cotization_date <= ?", @reference_period).sum(:number_of_quotas) >
            fi.redemptions.where("cotization_date <= ?", @reference_period).sum(:redeemed_quotas)
      end

      effective_initial_balance = ->(perf) do
        if perf.initial_balance&.positive?
          perf.initial_balance
        elsif perf.monthly_return&.nonzero? && perf.earnings
          (perf.earnings / (perf.monthly_return / BigDecimal("100"))).abs
        else
          BigDecimal("0")
        end
      end

      total_initial_balance = active_performance.sum { |p| effective_initial_balance.call(p) }
      @total_earnings = active_performance.sum(&:earnings)

      if total_initial_balance > 0
        @portfolio_return = (@total_earnings / total_initial_balance) * 100

        weighted_12m = BigDecimal("0")
        active_performance.each do |perf|
          weight = effective_initial_balance.call(perf) / total_initial_balance
          weighted_12m += (perf.last_12_months_return || 0) * weight
        end

        @portfolio_12m_return = weighted_12m
      end
    end

      primary_benchmark_name = @portfolio.fund_investments
                                         .joins(:investment_fund)
                                         .group("investment_funds.benchmark_index")
                                         .order("count_all DESC")
                                         .count
                                         .keys.first || "CDI"

      target_index = EconomicIndex.find_by(abbreviation: primary_benchmark_name)

      @benchmark_series = []
      if target_index
        cumulative_bench = BigDecimal("1.0")

        histories = target_index.economic_index_histories
                                .where("date >= ? AND date <= ?", @reference_date.beginning_of_year, @reference_date)
                                .order(:date)

        histories.each do |h|
          variation = (h.value || 0) / BigDecimal("100")
          cumulative_bench *= (1 + variation)
          @benchmark_series << [I18n.l(h.date, format: "%b/%y"), ((cumulative_bench - 1) * 100).to_f.round(2)]
        end
      end

      @portfolio_yield_series = []
      cumulative_port = BigDecimal("1.0")

      @portfolio.performance_histories
                .where("period >= ? AND period <= ?", @reference_date.beginning_of_year, @reference_date)
                .select("period, SUM(earnings) as total_earnings, SUM(initial_balance) as total_balance")
                .group(:period).order(:period).each do |hist|
        if hist.total_balance.to_f > 0
          m_return = hist.total_earnings / hist.total_balance
          cumulative_port *= (1 + m_return)
          @portfolio_yield_series << [I18n.l(hist.period, format: "%b/%y"), ((cumulative_port - 1) * 100).to_f.round(2)]
        end
      end

      @current_benchmark_label = target_index&.name || "Benchmark"

      @compliance_report = @portfolio.portfolio_normative_articles.map do |pna|
        actual_alloc = @normative_data[pna.normative_article.article_number] || 0
        {
          article: pna.normative_article.article_number,
          actual: actual_alloc.to_f,
          min: pna.minimum_target.to_f,
          max: pna.maximum_target.to_f,
          target: pna.benchmark_target.to_f,
          status: (actual_alloc >= pna.minimum_target && actual_alloc <= pna.maximum_target) ? "success" : "danger"
        }
      end

      peak = 0
      @drawdown_series = @portfolio_yield_series.map do |date, return_pct|
        peak = [peak, return_pct].max
        drawdown = peak == 0 ? 0 : ((return_pct - peak))
        [date, drawdown.round(2)]
      end
  end

  def new
    @portfolio = Portfolio.new
    @normative_articles = NormativeArticle.all.map { |a| [a.display_name, a.id] }
  end

  def edit
    @normative_articles = NormativeArticle.all.map { |a| [a.display_name, a.id] }
  end

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
                     Date.current.prev_month.beginning_of_month
                   end

  # If you want to calculate April, the target_date passed to the Job
  # must be in May, because the job logic uses target_date.prev_month[cite: 1, 3]
  target_date = selected_month.next_month.end_of_month

  PerformanceCalculationJob.perform_later(target_date: target_date)

  # Redirect back to the end of the month we are actually calculating
  redirect_to portfolio_path(@portfolio, reference_date: selected_month.end_of_month),
              notice: "Cálculo de #{I18n.l(selected_month, format: '%B/%Y')} iniciado!"
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

  def calculation_progress
    month = params[:month] || Date.current.strftime("%Y-%m")
    progress_key = "calc_progress_#{@portfolio.id}_#{month}"
    data = Rails.cache.read(progress_key) || { percent: 0, step: "Aguardando…", done: false }

    render json: data
  end

  private

  def set_portfolio
    @portfolio = Portfolio.for_user(current_user).find(params[:id])
  end

  def authorize_portfolio_management!
    authorize! :manage, @portfolio
  end

  def portfolio_params
    params.require(:portfolio).permit(
      :name,
      :user_id,
      :annual_interest_rate,
      :shared_user_id,
      portfolio_normative_articles_attributes: [
        :id,
        :normative_article_id,
        :benchmark_target,
        :minimum_target,
        :maximum_target,
        :_destroy
      ]
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

  def pdf_export_title = "Carteiras"

  def pdf_export_subtitle = "Lista de carteiras com permissão de visualização"

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
