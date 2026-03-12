# === fund_investments_controller.rb
#
# Description:: Manages the creation, listing, and detailed viewing of a user's
#               investments in specific funds.
#
# Usage:: - *What* - A management tool for tracking individual fund investments
#           within a user's portfolio.
#         - *How* - It allows users to create, update, and remove investment
#           records while ensuring data security and proper authorization.
#         - *Why* - Accurate investment tracking is vital for calculating a
#           portfolio's performance and asset allocation.
#
# Attributes:: - *@fund_investment* [FundInvestment] - The record currently being processed.
#              - *@fund_investments* [Collection] - The filtered list of investment records.
#
class FundInvestmentsController < ApplicationController

  include PdfExportable

  # =============================================================
  #                        CONFIGURATION
  # =============================================================

  # Lists permitted columns for sorting to prevent malicious SQL queries.
  FUND_INVESTMENTS_ALLOWED_SORT_COLUMNS = %w[
    total_invested_value total_quotas_held percentage_allocation created_at
  ].freeze

  # Lists permitted directions for sorting to ensure query safety.
  FUND_INVESTMENTS_ALLOWED_DIRECTIONS = %w[asc desc].freeze

  # Confirms that a user is logged into the system before access.
  before_action :authenticate_user!

  # Loads the investment record for specific operations before they occur.
  before_action :load_fund_investment, only: %i[show update edit destroy]

  # Ensures only authorized users can view or modify specific investments.
  before_action :authorize_fund_investment, only: %i[show update edit destroy]

  # Prepares necessary data for rendering forms like new or edit screens.
  before_action :load_form_dependencies, only: %i[new edit create]

  # =============================================================
  #                      ERROR HANDLING
  # =============================================================

  # Handles missing records by redirecting the user back to the list.
  rescue_from ActiveRecord::RecordNotFound do |e|
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: "Investimento não encontrado." }
      format.json { render json: { error: e.message }, status: :not_found }
    end
  end

  # Handles authorization failures by warning the user of restricted access.
  rescue_from CanCan::AccessDenied do |e|
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: e.message }
      format.json { render json: { error: e.message }, status: :forbidden }
    end
  end

  # Captures unexpected system errors and logs details for debugging.
  rescue_from StandardError do |e|
    Rails.logger.error("[FundInvestmentsController] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: "Ocorreu um erro inesperado." }
      format.json { render json: { error: "Internal server error" }, status: :internal_server_error }
    end
  end

  # =============================================================
  #                       PUBLIC METHODS
  # =============================================================

  # == index
  #
  # @author Moisés Reis
  #
  # Displays a list of all accessible investments for the user.
  # It applies sorting and pagination to keep the view organized.
  def index
    base_scope = accessible_fund_investments

    @q = base_scope.ransack(params[:q])
    @total_items = FundInvestment.count

    filtered = @q.result(distinct: true)

    # Validates sort parameters to prevent SQL injection attempts.
    sort = FUND_INVESTMENTS_ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "total_invested_value"
    direction = FUND_INVESTMENTS_ALLOWED_DIRECTIONS.include?(params[:direction]) ? params[:direction] : "desc"

    @fund_investments = filtered.order("#{sort} #{direction}").page(params[:page]).per(14)

    respond_to { |f| f.html }
  end

  # == show
  #
  # @author Moisés Reis
  #
  # Displays the details of a single fund investment record.
  def show
  end

  # == new
  #
  # @author Moisés Reis
  #
  # Prepares a blank investment record for the entry form.
  def new
    @fund_investment = FundInvestment.new
  end

  # == create
  #
  # @author Moisés Reis
  #
  # Saves a new investment entry and redirects to the portfolio view.
  def create
    @fund_investment = FundInvestment.new(fund_investment_params)

    if @fund_investment.save
      redirect_to @fund_investment.portfolio, notice: "Investimento criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # == update
  #
  # @author Moisés Reis
  #
  # Placeholder for updating an existing investment record.
  def update
  end

  # == destroy
  #
  # @author Moisés Reis
  #
  # Removes the investment record and returns to the portfolio.
  def destroy
    portfolio = @fund_investment.portfolio
    @fund_investment.destroy
    redirect_to portfolio, notice: "Investimento removido com sucesso."
  end

  # == edit
  #
  # @author Moisés Reis
  #
  # Placeholder for editing an existing investment record.
  def edit
  end

  # == delete
  #
  # @author Moisés Reis
  #
  # Placeholder for handling the deletion flow.
  def delete
  end

  # =============================================================
  #                       HELPER UTILITIES
  # =============================================================

  private

  # Retrieves the specific investment record from the database.
  def load_fund_investment
    @fund_investment = FundInvestment.find(params[:id])
  end

  # Checks user permissions for the current investment action.
  def authorize_fund_investment
    authorize! :read, @fund_investment if action_name == "show"
    authorize! :manage, @fund_investment if %w[update destroy edit].include?(action_name)
  end

  # Filters parameters allowed for saving investment data.
  def fund_investment_params
    params.require(:fund_investment).permit(
      :portfolio_id,
      :investment_fund_id,
      :total_invested_value,
      :total_quotas_held,
      :percentage_allocation
    )
  end

  # Returns the scope of investments visible to the current user.
  def accessible_fund_investments
    FundInvestment.accessible_to(current_user).includes(:portfolio, :investment_fund)
  end

  # Calculates the market value of an investment on a specific date.
  def market_value_on
    fund_investment = FundInvestment.find(params[:id])
    date = Date.parse(params[:date])
    quota = fund_investment.investment_fund.quota_value_on(date)
    quotas = fund_investment.applications.sum(:number_of_quotas) -
             fund_investment.redemptions.sum(:redeemed_quotas)
    value = quota ? (quotas * quota).round(2) : nil

    render json: { value: value, quota: quota, date: date }
  end

  # Loads data required to populate form dropdowns and fields.
  def load_form_dependencies
    @investment_funds = InvestmentFund.all
    @portfolios = accessible_portfolios
  end

  # Fetches portfolios owned by the current user.
  def accessible_portfolios
    current_user.portfolios
  end

  # Defines the title for the PDF export report.
  def pdf_export_title
    "Investimentos em Fundos"
  end

  # Defines the subtitle for the PDF export report.
  def pdf_export_subtitle
    "Relatório de investimentos ativos"
  end

  # Configures columns to be displayed in the PDF document.
  def pdf_export_columns
    h = ActionController::Base.helpers

    [
      { header: "Fundo", key: ->(fi) { fi.investment_fund.fund_name } },
      { header: "CNPJ", key: ->(fi) { fi.investment_fund.cnpj } },
      { header: "Carteira", key: ->(fi) { fi.portfolio.name } },
      {
        header: "Cotas",
        key: ->(fi) { h.number_with_precision(fi.total_quotas_held, precision: 2) },
        width: 80
      },
      {
        header: "Valor Investido",
        key: ->(fi) { view_context.standard_currency(fi.total_invested_value) },
        width: 100
      },
      {
        header: "Alocação",
        key: ->(fi) { "#{fi.percentage_allocation}%" },
        width: 70
      }
    ]
  end

  # Compiles the raw data to be used in the PDF export.
  def pdf_export_data
    FundInvestment.joins(:portfolio)
                  .where(portfolios: { user_id: current_user.id })
                  .includes(:investment_fund, :portfolio)
  end

  # Compiles metadata for the summary section of the PDF.
  def pdf_export_metadata
    h = ActionController::Base.helpers

    {
      "Usuário" => current_user.full_name,
      "Total investido" => h.number_to_currency(pdf_export_data.sum(:total_invested_value))
    }
  end
end