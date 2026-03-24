# =============================================================
# Configuration & Dependencies
# =============================================================

# Define the allowed database columns for sorting portfolio lists.
#
# This array whitelists specific attributes to prevent SQL injection and
# ensures that sorting requests remain within the defined architectural boundaries.
PORTFOLIOS_ALLOWED_SORT_COLUMNS = %w[id name created_at updated_at].freeze

# Define the allowed directions for ordering portfolio results.
#
# This constant restricts sorting to ascending or descending order,
# preventing invalid order clauses from being passed to the database.
PORTFOLIOS_ALLOWED_DIRECTIONS = %w[asc desc].freeze

# === portfolios_controller.rb
#
# Description:: Manages the lifecycle of investment portfolios within the system.
#               This controller handles the creation, analysis, and reporting of
#               financial portfolios, providing detailed performance metrics and
#               automated calculation triggers for users and administrators.
#
# Usage:: - *What* - Serves as the primary interface for portfolio management and financial dashboarding.
#         - *How* - Utilizes +Ransack+ for filtering, +Kaminari+ for pagination, and background jobs for heavy performance calculations.
#         - *Why* - To centralize investment tracking, allow shared access permissions, and generate analytical PDF reports.
#
# Attributes:: - *@portfolio* [Portfolio] - The specific portfolio record currently being accessed or modified.
#              - *@portfolios* [Relation] - A paginated collection of portfolios available to the current user.
#              - *@reference_date* [Date] - The temporal anchor used to filter historical performance data.
#
# View:: - +PortfoliosView+
#
# Notes:: Includes modules +PdfExportable+ for list exports and +MonthlyReportable+ for analytical PDF generation.
#         Access is controlled via **Devise** authentication and **CanCanCan** authorization.
#
class PortfoliosController < ApplicationController

  # Explain what this line does in two or three lines.
  # Provides the infrastructure for exporting the index list into PDF format.
  include PdfExportable

  # Explain what this line does in two or three lines.
  # Adds capabilities for generating detailed monthly performance reports.
  include MonthlyReportable

  # Explain what this line does in two or three lines.
  # Ensures only logged-in users can access portfolio management actions.
  before_action :authenticate_user!

  # Explain what this line does in two or three lines.
  # Locates the specific portfolio record before executing member actions.
  before_action :set_portfolio, only: %i[show edit update destroy monthly_report run_calculations calculation_progress]

  # Explain what this line does in two or three lines.
  # Validates that the user has sufficient permissions to modify or calculate the portfolio.
  before_action :authorize_portfolio_management!, only: %i[edit update destroy run_calculations monthly_report calculation_progress]

  # =============================================================
  # Error handling
  # =============================================================

  # Explain what this line does in two or three lines.
  # Gracefully redirects the user if they attempt to access a portfolio that does not exist.
  rescue_from ActiveRecord::RecordNotFound do |e|
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: "Carteira não encontrada." }
      format.json { render json: { error: e.message }, status: :not_found }
    end
  end

  # Explain what this line does in two or three lines.
  # Handles unauthorized access attempts by redirecting with a security alert message.
  rescue_from CanCan::AccessDenied do |e|
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: e.message }
      format.json { render json: { error: e.message }, status: :forbidden }
    end
  end

  # Explain what this line does in two or three lines.
  # Logs unexpected errors and provides a generic failure message to the end user.
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

  # == index
  # @author Moisés Reis
  #
  # Lists all portfolios accessible to the user with support for searching and sorting.
  # Admins see all records, while standard users see only their own or shared portfolios.
  #
  # Returns::
  # - An HTML page containing a paginated list of portfolio records.
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

  # == show
  # @author Moisés Reis
  #
  # Displays the detailed analytical dashboard for a specific portfolio.
  # It calculates market values, asset allocation, and returns for a chosen reference date.
  #
  # Returns::
  # - A comprehensive view with performance charts and detailed investment breakdowns.
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

    # Aggregates allocation percentages grouped by the investment fund's benchmark index.
    @indices_data = @portfolio.fund_investments
                              .joins(:investment_fund)
                              .group("investment_funds.benchmark_index")
                              .sum(:percentage_allocation)
                              .transform_keys { |key| key.presence || "Outros" }

    # Joins fund investments to normative articles through the join table
    # to aggregate allocation percentages by the article number.
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
  end

  # == new
  # @author Moisés Reis
  #
  # Initializes a fresh portfolio instance for the creation form.
  #
  # Returns::
  # - A blank portfolio object ready for attribute assignment.
  def new
    @portfolio = Portfolio.new
  end

  # == edit
  # @author Moisés Reis
  #
  # Prepares the existing portfolio for modification.
  #
  # Returns::
  # - The targeted portfolio instance to be displayed in an edit form.
  def edit; end

  # == create
  # @author Moisés Reis
  #
  # Persists a new portfolio record and optionally grants permissions to other users.
  #
  # Returns::
  # - A redirect to the portfolio dashboard on success or a re-rendered form on failure.
  def create
    @portfolio = Portfolio.new(portfolio_params.except(:shared_user_id))

    if @portfolio.save
      grant_permission_if_present
      redirect_to @portfolio, notice: "Carteira criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # == update
  # @author Moisés Reis
  #
  # Updates the attributes of an existing portfolio and manages sharing settings.
  #
  # Returns::
  # - A redirect to the portfolio dashboard or a validation error state.
  def update
    if @portfolio.update(portfolio_params.except(:shared_user_id))
      grant_permission_if_present
      redirect_to @portfolio, notice: "Carteira atualizada com sucesso.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # == destroy
  # @author Moisés Reis
  #
  # Removes the portfolio record permanently from the database.
  #
  # Returns::
  # - A redirect to the index page with a confirmation notice.
  def destroy
    @portfolio.destroy!
    redirect_to portfolios_path, notice: "Carteira deletada com sucesso.", status: :see_other
  end

  # == run_calculations
  # @author Moisés Reis
  #
  # Enqueues a background job to recalculate financial performance for a given month.
  #
  # Returns::
  # - A redirect to the portfolio with a notice that the background process has started.
  def run_calculations
    selected_month = if params[:month].present?
                       Date.strptime(params[:month], "%Y-%m")
                     else
                       Date.yesterday.prev_month.beginning_of_month
                     end

    target_date = selected_month.next_month.end_of_month

    PerformanceCalculationJob.perform_later(target_date: target_date)

    redirect_to portfolio_path(@portfolio, reference_date: selected_month.end_of_month),
                notice: "Cálculo de #{I18n.l(selected_month, format: '%B/%Y')} iniciado em segundo plano!"
  end

  # == monthly_report
  # @author Moisés Reis
  #
  # Generates and serves a PDF file containing the portfolio's monthly analytical report.
  #
  # Returns::
  # - Binary PDF data sent directly to the user's browser for viewing.
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

  # == calculation_progress
  # @author Moisés Reis
  #
  # Checks the current status of the background performance calculation from the cache.
  #
  # Returns::
  # - A JSON object containing the percentage completion and current step description.
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
  # @author Moisés Reis
  #
  # Retrieves a specific portfolio from the scope allowed for the current user.
  #
  # Attributes:: - *@portfolio* - The resulting instance or an error if not found.
  def set_portfolio
    @portfolio = Portfolio.for_user(current_user).find(params[:id])
  end

  # == authorize_portfolio_management!
  # @author Moisés Reis
  #
  # Validates that the current user has administrative or management rights over the portfolio.
  def authorize_portfolio_management!
    authorize! :manage, @portfolio
  end

  # == portfolio_params
  # @author Moisés Reis
  #
  # Filters and permits parameters for portfolio creation and updates.
  #
  # Returns::
  # - A sanitized hash of portfolio attributes.
  def portfolio_params
    params.require(:portfolio).permit(
      :name,
      :user_id,
      :annual_interest_rate,
      :shared_user_id
    )
  end

  # == grant_permission_if_present
  # @author Moisés Reis
  #
  # Creates a new permission record if a shared user ID is provided in the params.
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

  # == calculate_monthly_flows
  # @author Moisés Reis
  #
  # Aggregates application and redemption totals for each month of the current year.
  #
  # Parameters:: - *portfolio* - The portfolio instance to analyze.
  #
  # Returns::
  # - A structured array of monthly transaction data for charting.
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

  # == pdf_export_title
  # @author Moisés Reis
  #
  # Defines the main title for the exported PDF document.
  def pdf_export_title = "Carteiras"

  # == pdf_export_subtitle
  # @author Moisés Reis
  #
  # Provides a brief subtitle explaining the contents of the PDF list.
  def pdf_export_subtitle = "Lista de carteiras com permissão de visualização"

  # == pdf_export_columns
  # @author Moisés Reis
  #
  # Configures the specific columns and formatting logic for the PDF data table.
  #
  # Returns::
  # - An array of column configuration hashes.
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

  # == pdf_export_data
  # @author Moisés Reis
  #
  # Retrieves and filters the portfolio data that will be included in the export.
  def pdf_export_data
    base_scope = current_user.admin? ? Portfolio.all : Portfolio.for_user(current_user)
    @q = base_scope.ransack(params[:q])
    @q.result(distinct: true)
  end

  # == pdf_export_metadata
  # @author Moisés Reis
  #
  # Includes secondary information in the export, such as the generating user's name.
  def pdf_export_metadata
    { "Gerado por" => current_user.full_name }
  end
end