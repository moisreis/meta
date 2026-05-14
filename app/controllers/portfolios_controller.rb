# Handles portfolio management workflows, dashboard rendering,
# reporting, calculation orchestration, and portfolio lifecycle actions.
#
# Coordinates HTTP request handling for portfolio-related operations,
# delegating business logic to query objects, service objects, form
# objects, PDF generators, and background jobs.
#
# @author Moisés Reis
#
class PortfoliosController < ApplicationController

  # ============================================================================
  # CONTROLLER CONFIGURATION
  # ============================================================================

  include MonthlyReportable

  before_action :authenticate_user!

  before_action :set_portfolio,
                only: %i[
                  show
                  edit
                  update
                  destroy
                  monthly_report
                  run_calculations
                  calculation_progress
                ]

  before_action :authorize_portfolio_management!,
                only: %i[
                  edit
                  update
                  destroy
                  run_calculations
                  monthly_report
                  calculation_progress
                ]

  before_action :load_normative_articles,
                only: %i[new edit create update]

  # ============================================================================
  # EXCEPTION HANDLING
  # ============================================================================

  # Handles missing portfolio records.
  #
  # @return [void]
  # @raise [ActiveRecord::RecordNotFound]
  rescue_from ActiveRecord::RecordNotFound do |e|
    respond_to do |format|
      format.html do
        redirect_to portfolios_path, alert: "Carteira não encontrada."
      end

      format.json do
        render json: { error: e.message }, status: :not_found
      end
    end
  end

  # Handles authorization failures.
  #
  # @return [void]
  # @raise [CanCan::AccessDenied]
  rescue_from CanCan::AccessDenied do |e|
    respond_to do |format|
      format.html do
        redirect_to portfolios_path, alert: e.message
      end

      format.json do
        render json: { error: e.message }, status: :forbidden
      end
    end
  end

  # ============================================================================
  # PUBLIC ACTIONS — DASHBOARD & LISTING
  # ============================================================================

  # Lists portfolios.
  #
  # @return [void]
  # @raise [StandardError]
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

  # Shows portfolio dashboard.
  #
  # @return [void]
  # @raise [ArgumentError]
  # @raise [StandardError]
  def show
    @data = Portfolios::ShowService.call(
      @portfolio,
      reference_date: Portfolios::ReferenceDateResolver.call(params[:reference_date])
    )

    @reference_date = @data.reference_date
    @reference_period = @data.reference_period
  end

  # ============================================================================
  # PUBLIC ACTIONS — CREATION
  # ============================================================================

  # Renders creation form.
  #
  # @return [void]
  def new
    @form = PortfolioForm.new(user_id: current_user.id)
  end

  # Creates portfolio.
  #
  # @return [void]
  # @raise [ActiveRecord::RecordInvalid]
  # @raise [CanCan::AccessDenied]
  def create
    result = Portfolios::CreationService.call(portfolio_params, actor: current_user)

    if result.success?
      redirect_to result.portfolio, notice: "Carteira criada com sucesso."
    else
      @form = result.form
      render :new, status: :unprocessable_entity
    end
  end

  # ============================================================================
  # PUBLIC ACTIONS — UPDATES
  # ============================================================================

  # Renders edit form.
  #
  # @return [void]
  def edit
    @form = PortfolioForm.from_portfolio(@portfolio)
  end

  # Updates portfolio.
  #
  # @return [void]
  # @raise [ActiveRecord::RecordInvalid]
  # @raise [CanCan::AccessDenied]
  def update
    result = Portfolios::UpdateService.call(
      @portfolio,
      portfolio_params,
      actor: current_user
    )

    if result.success?
      redirect_to result.portfolio,
                  notice: "Carteira atualizada com sucesso.",
                  status: :see_other
    else
      @form = result.form
      render :edit, status: :unprocessable_entity
    end
  end

  # ============================================================================
  # PUBLIC ACTIONS — DELETION
  # ============================================================================

  # Deletes portfolio.
  #
  # @return [void]
  # @raise [CanCan::AccessDenied]
  def destroy
    result = Portfolios::DeletionService.call(@portfolio, actor: current_user)

    if result.success?
      redirect_to portfolios_path,
                  notice: "Carteira deletada com sucesso.",
                  status: :see_other
    else
      redirect_to portfolios_path,
                  alert: "Não foi possível deletar a carteira.",
                  status: :see_other
    end
  end

  # ============================================================================
  # PUBLIC ACTIONS — REPORTING & CALCULATIONS
  # ============================================================================

  # Enqueues portfolio calculations.
  #
  # @return [void]
  # @raise [ArgumentError]
  def run_calculations
    selected_month = selected_calculation_month
    target_date = selected_month.end_of_month

    PerformanceCalculationJob.perform_later(target_date: target_date)

    redirect_to portfolio_path(@portfolio, reference_date: target_date),
                notice: "Cálculo de #{I18n.l(selected_month, format: '%B/%Y')} iniciado!"
  end

  # Generates monthly report PDF.
  #
  # @return [void]
  # @raise [ArgumentError]
  # @raise [StandardError]
  def monthly_report
    reference_date = Portfolios::ReportDateResolver.call(
      day: params[:day].presence&.to_i,
      month: params[:month].presence&.to_i,
      year: params[:year].presence&.to_i
    )

    generator = PortfolioMonthlyReportGenerator.new(@portfolio, reference_date)
    pdf_bytes = generator.generate

    send_data pdf_bytes,
              filename: "relatorio_#{@portfolio.id}_#{reference_date.strftime('%Y-%m-%d')}.pdf",
              type: "application/pdf",
              disposition: "inline"
  rescue StandardError => e
    Rails.logger.error("[monthly_report] #{e.class}: #{e.message}\n#{e.backtrace.first(10).join("\n")}")
    raise
  end

  # Returns calculation progress.
  #
  # @return [void]
  def calculation_progress
    month = params[:month] || Date.current.strftime("%Y-%m")
    render json: @portfolio.calculation_progress_for(month)
  end

  # ============================================================================
  # PRIVATE — DATA LOADING
  # ============================================================================

  private

  # Loads normative articles.
  #
  # @return [Array<Array(String, Integer)>]
  def load_normative_articles
    @normative_articles = NormativeArticle.for_select
  end

  # Resolves calculation month.
  #
  # @return [Date]
  def selected_calculation_month
    return Date.current.prev_month.beginning_of_month unless params[:month].present?

    Date.strptime(params[:month], "%Y-%m")
  end

  # Loads portfolio.
  #
  # @return [Portfolio]
  # @raise [ActiveRecord::RecordNotFound]
  def set_portfolio
    @portfolio = Portfolio.for_user(current_user).find(params[:id])
  end

  # ============================================================================
  # PRIVATE — AUTHORIZATION
  # ============================================================================

  # Authorizes portfolio management.
  #
  # @return [void]
  # @raise [CanCan::AccessDenied]
  def authorize_portfolio_management!
    authorize! :manage, @portfolio
  end

  # ============================================================================
  # PRIVATE — PARAMETER SANITIZATION
  # ============================================================================

  # Strong parameters.
  #
  # @return [ActionController::Parameters]
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
end
