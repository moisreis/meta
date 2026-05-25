# Manages portfolio management workflows, dashboard rendering,
# reporting, calculation orchestration, and portfolio lifecycle actions.
#
# This controller acts as the HTTP orchestration layer for
# {Portfolio} resources. Business rules, dashboard composition,
# PDF generation, and background job orchestration are delegated
# to dedicated service and query objects under the Portfolios
# namespace.
#
# This controller does NOT implement financial calculations
# directly. Calculation logic belongs to dedicated calculators
# under the Calculators namespace.
#
# @author Moisés Reis

class PortfoliosController < ApplicationController

  # =============================================================
  #                   FILTERS & ERROR HANDLING
  # =============================================================

  # --- INCLUDES ------------------------------------------------

  include MonthlyReportable

  # --- FILTERS -------------------------------------------------

  before_action :authenticate_user!

  # --- RESOURCE LOADING ----------------------------------------

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

  # --- AUTHORIZATION -------------------------------------------

  before_action :authorize_portfolio_management!,
                only: %i[
                  edit
                  update
                  destroy
                  run_calculations
                  monthly_report
                  calculation_progress
                ]

  # --- FORM DEPENDENCIES ---------------------------------------

  before_action :load_normative_articles,
                only: %i[new edit create update]

  # --- ERROR HANDLING ------------------------------------------

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

  # =============================================================
  #                    INDEX & VISUALIZATION
  # =============================================================

  # --- INDEX ---------------------------------------------------

  # Displays a searchable and paginated collection of
  # accessible portfolio records.
  #
  # Filtering, sorting, pagination, and authorization
  # scoping are delegated to {Portfolios::IndexQuery}.
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

  # --- SHOW ----------------------------------------------------

  # Displays the portfolio dashboard with aggregated
  # metrics, charts, and recent activity.
  #
  # Dashboard data composition is delegated to
  # {Portfolios::ShowService}.
  #
  # @return [void]
  def show
    @data = Portfolios::ShowService.call(
      @portfolio,
      reference_date: Portfolios::ReferenceDateResolver.call(params[:reference_date])
    )

    @new_application = Application.new
    @new_redemption  = Redemption.new

    @reference_date = @data.reference_date
    @reference_period = @data.reference_period
  end

  # =============================================================
  #                          CREATION
  # =============================================================

  # --- NEW -----------------------------------------------------

  # Renders the creation form for a new portfolio.
  #
  # @return [void]
  def new
    @form = PortfolioForm.new(user_id: current_user.id)
  end

  # --- CREATE --------------------------------------------------

  # Creates a portfolio associated with the
  # authenticated user.
  #
  # Persistence logic and business validations are
  # delegated to {Portfolios::CreationService}.
  #
  # @return [void]
  def create
    result = Portfolios::CreationService.call(portfolio_params, actor: current_user)

    if result.success?
      redirect_to result.portfolio, notice: "Carteira criada com sucesso."
    else
      @form = result.form
      render :new, status: :unprocessable_entity
    end
  end

  # =============================================================
  #                           UPDATE
  # =============================================================

  # --- EDIT ----------------------------------------------------

  # Renders the edition form for an existing portfolio.
  #
  # The form is pre-populated from the persisted
  # portfolio record via {PortfolioForm.from_portfolio}.
  #
  # @return [void]
  def edit
    @form = PortfolioForm.from_portfolio(@portfolio)
  end

  # --- UPDATE --------------------------------------------------

  # Updates an existing portfolio.
  #
  # Persistence workflows and validation rules are
  # delegated to {Portfolios::UpdateService}.
  #
  # @return [void]
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

  # =============================================================
  #                          DELETION
  # =============================================================

  # --- DESTROY -------------------------------------------------

  # Deletes an existing portfolio.
  #
  # Deletion workflows and integrity validation are
  # delegated to {Portfolios::DeletionService}.
  #
  # @return [void]
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

  # =============================================================
  #                  REPORTING & CALCULATIONS
  # =============================================================

  # --- RUN CALCULATIONS ----------------------------------------

  # Enqueues portfolio performance calculations for
  # a target month.
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

  # --- MONTHLY REPORT ------------------------------------------

  # Generates and streams a monthly report PDF.
  #
  # PDF generation is delegated to
  # {PortfolioMonthlyReportGenerator}.
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

  # --- CALCULATION PROGRESS ------------------------------------

  # Returns the current progress of portfolio calculations
  # for a given month.
  #
  # @return [void]
  def calculation_progress
    month = params[:month] || Date.current.strftime("%Y-%m")
    render json: @portfolio.calculation_progress_for(month)
  end

  private

  # =============================================================
  #                        RESOURCE LOADING
  # =============================================================

  # --- FORM DEPENDENCIES ---------------------------------------

  # Loads normative articles for form selectors.
  #
  # @return [Array<Array(String, Integer)>]
  def load_normative_articles
    @normative_articles = NormativeArticle.for_select
  end

  # --- MONTH RESOLUTION ----------------------------------------

  # Resolves the target calculation month from parameters.
  #
  # @return [Date]
  def selected_calculation_month
    return Date.current.prev_month.beginning_of_month unless params[:month].present?

    Date.strptime(params[:month], "%Y-%m")
  end

  # --- RESOURCE FINDING ----------------------------------------

  # Loads the target portfolio from request parameters.
  #
  # @raise [ActiveRecord::RecordNotFound]
  #   Raised when the portfolio does not exist.
  #
  # @return [Portfolio]
  def set_portfolio
    @portfolio = Portfolio.for_user(current_user).find(params[:id])
  end

  # =============================================================
  #                        AUTHORIZATION
  # =============================================================

  # Authorizes portfolio management actions for the
  # current user.
  #
  # Authorization is enforced through CanCanCan.
  #
  # @raise [CanCan::AccessDenied]
  #   Raised when the current user lacks permission.
  #
  # @return [void]
  def authorize_portfolio_management!
    authorize! :manage, @portfolio
  end

  # =============================================================
  #                      STRONG PARAMETERS
  # =============================================================

  # Defines the permitted parameters for portfolio
  # persistence operations.
  #
  # @return [ActionController::Parameters]
  #   Sanitized parameters allowed for persistence.
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
