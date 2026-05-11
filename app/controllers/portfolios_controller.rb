class PortfoliosController < ApplicationController

  include PdfExportable
  include MonthlyReportable

  before_action :authenticate_user!
  before_action :set_portfolio, only: %i[show edit update destroy monthly_report run_calculations calculation_progress]
  before_action :authorize_portfolio_management!, only: %i[edit update destroy run_calculations monthly_report calculation_progress]
  before_action :load_normative_articles,
                only: %i[new edit create update]

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
  #                           INDEX
  # =============================================================

  # Displays the portfolio listing page.
  #
  # Delegates searching, filtering, authorization scoping,
  # sorting, eager loading, and pagination responsibilities
  # to {Portfolios::IndexQuery}.
  #
  # @return [void]
  def index
    result = Portfolios::IndexQuery.call(
      params[:q],
      page: params[:page],
      sort: params[:sort],
      direction: params[:direction],
      actor: current_user
    )

    @q = result.search
    @portfolios = result.records
    @total_items = result.total_items
  end

  # =============================================================
  #                           SHOW
  # =============================================================

  # Displays the portfolio dashboard.
  #
  # Delegates all dashboard aggregation, chart assembly,
  # performance calculations, compliance analysis, and
  # transactional summaries to {Portfolios::ShowService}.
  #
  # @return [void]
  def show
    @data = Portfolios::ShowService.call(
      @portfolio,
      reference_date: parsed_reference_date
    )

    @reference_date = @data.reference_date
    @reference_period = @data.reference_period
  end

  # =============================================================
  #                      PORTFOLIO CREATION
  # =============================================================

  # Renders the portfolio creation form.
  #
  # Initializes a new {PortfolioForm} instance associated with the
  # currently authenticated user and loads the available normative
  # articles required by the nested investment policy fields.
  #
  # @return [void]
  def new
    @form = PortfolioForm.new(
      user_id: current_user.id
    )

    load_normative_articles
  end

  # Creates a new portfolio and its associated investment policy data.
  #
  # Delegates portfolio persistence, validation, and business-rule
  # orchestration to {Portfolios::CreationService}.
  #
  # Redirects to the created portfolio on success. Re-renders the
  # form with validation errors on failure.
  #
  # @return [void]
  def create
    result = Portfolios::CreationService.call(
      portfolio_params,
      actor: current_user
    )

    if result.success?
      redirect_to(
        result.portfolio,
        notice: "Carteira criada com sucesso."
      )
    else
      @form = result.form

      load_normative_articles

      render :new, status: :unprocessable_entity
    end
  end

  # =============================================================
  #                      PORTFOLIO UPDATES
  # =============================================================

  # Renders the portfolio editing form.
  #
  # Hydrates a {PortfolioForm} instance using the persisted
  # portfolio state and loads the normative articles required
  # by the nested policy configuration interface.
  #
  # @return [void]
  def edit
    @form = PortfolioForm.from_portfolio(@portfolio)

    load_normative_articles
  end

  # Updates an existing portfolio and its associated policy data.
  #
  # Delegates validation, persistence, and domain-level update
  # orchestration to {Portfolios::UpdateService}.
  #
  # Redirects to the updated portfolio on success. Re-renders
  # the edit form with validation errors on failure.
  #
  # @return [void]
  def update
    result = Portfolios::UpdateService.call(
      @portfolio,
      portfolio_params,
      actor: current_user
    )

    if result.success?
      redirect_to(
        result.portfolio,
        notice: "Carteira atualizada com sucesso.",
        status: :see_other
      )
    else
      @form = result.form

      load_normative_articles

      render :edit, status: :unprocessable_entity
    end
  end

  # =============================================================
  #                     PORTFOLIO DELETION
  # =============================================================

  # Deletes the selected portfolio.
  #
  # Delegates authorization checks, dependency handling,
  # and deletion orchestration to {Portfolios::DeletionService}.
  #
  # Redirects back to the portfolio index with a status message
  # indicating whether the operation succeeded.
  #
  # @return [void]
  def destroy
    result = Portfolios::DeletionService.call(
      @portfolio,
      actor: current_user
    )

    if result.success?
      redirect_to(
        portfolios_path,
        notice: "Carteira deletada com sucesso.",
        status: :see_other
      )
    else
      redirect_to(
        portfolios_path,
        alert: "Não foi possível deletar a carteira.",
        status: :see_other
      )
    end
  end

  def run_calculations
    selected_month = if params[:month].present?
                       Date.strptime(params[:month], "%Y-%m")
                     else
                       Date.current.prev_month.beginning_of_month
                     end

    target_date = selected_month.end_of_month # ← remova o .next_month

    PerformanceCalculationJob.perform_later(target_date: target_date)

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

  def load_normative_articles
    @normative_articles = NormativeArticle.all.map do |article|
      [article.display_name, article.id]
    end
  end

  def parsed_reference_date
    return Date.current unless params[:reference_date].present?

    Date.parse(params[:reference_date])
  rescue ArgumentError
    Date.current
  end

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
