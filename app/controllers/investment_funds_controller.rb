# === investment_funds_controller.rb
#
# Description:: Manages all available InvestmentFund records in the system,
#               handling their creation, updates, and organizational details.
#
# Usage:: - *What* - A centralized manager for financial fund records.
#         - *How* - It uses RESTful actions to handle user input, sanitizing
#           sort parameters to prevent security risks while ensuring authorized
#           access to sensitive fund information.
#         - *Why* - It ensures that the system maintains a consistent and secure
#           repository of investment funds used across the application.
#
# Attributes:: - *@investment_funds* [Collection] - A list of available fund records.
#              - *@investment_fund* [Object] - A single specific fund being processed.
#
class InvestmentFundsController < ApplicationController

  # =============================================================
  #                        CONFIGURATION
  # =============================================================

  # Lists permitted columns for sorting to prevent malicious SQL queries.
  INVESTMENT_FUNDS_ALLOWED_SORT_COLUMNS = %w[cnpj fund_name administrator_name created_at].freeze

  # Lists permitted directions for sorting to ensure query safety.
  INVESTMENT_FUNDS_ALLOWED_DIRECTIONS = %w[asc desc].freeze

  # Confirms that a user is logged into the system before access.
  before_action :authenticate_user!

  # Loads the investment fund record for specific operations before they occur.
  before_action :load_investment_fund, only: %i[show edit update destroy]

  # Ensures only authorized users can view or modify specific fund records.
  before_action :authorize_investment_fund, only: %i[show update destroy]

  # =============================================================
  #                      ERROR HANDLING
  # =============================================================

  # Handles missing records by redirecting the user back to the list.
  rescue_from ActiveRecord::RecordNotFound do |e|
    respond_to do |format|
      format.html { redirect_to investment_funds_path, alert: "Fundo não encontrado." }
      format.json { render json: { error: e.message }, status: :not_found }
    end
  end

  # Handles authorization failures by warning the user of restricted access.
  rescue_from CanCan::AccessDenied do |e|
    respond_to do |format|
      format.html { redirect_to investment_funds_path, alert: e.message }
      format.json { render json: { error: e.message }, status: :forbidden }
    end
  end

  # Captures unexpected system errors and logs details for debugging.
  rescue_from StandardError do |e|
    Rails.logger.error("[InvestmentFundsController] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    respond_to do |format|
      format.html { redirect_to investment_funds_path, alert: "Ocorreu um erro inesperado." }
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
  # Displays a paginated, searchable list of investment funds.
  def index
    if params.dig(:q, :cnpj_cont).present?
      digits = params[:q][:cnpj_cont].gsub(/\D/, "")
      params[:q][:cnpj_cont] = digits.sub(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '\1.\2.\3/\4-\5')
    end

    base_scope = InvestmentFund.all.order(created_at: :desc)

    @q = base_scope.ransack(params[:q])
    @total_items = InvestmentFund.count

    filtered = @q.result(distinct: true)

    # Validates sort parameters to prevent SQL injection attempts.
    sort = INVESTMENT_FUNDS_ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "cnpj"
    direction = INVESTMENT_FUNDS_ALLOWED_DIRECTIONS.include?(params[:direction]) ? params[:direction] : "asc"

    @models = filtered.order("#{sort} #{direction}").page(params[:page]).per(14)
    @investment_funds = @models

    respond_to { |f| f.html }
  end

  # == show
  #
  # @author Moisés Reis
  #
  # Displays the details of a single investment fund record.
  def show
  end

  # == new
  #
  # @author Moisés Reis
  #
  # Prepares a blank investment fund record for the entry form.
  def new
    @investment_fund = InvestmentFund.new
  end

  # == edit
  #
  # @author Moisés Reis
  #
  # Loads an existing fund record for the editing form.
  def edit
  end

  # == create
  #
  # @author Moisés Reis
  #
  # Saves a new investment fund entry and redirects to the view page.
  def create
    @investment_fund = InvestmentFund.new(investment_fund_params)
    authorize! :create, InvestmentFund

    if @investment_fund.save
      redirect_to @investment_fund, notice: "O credenciamento de fundo de investimento foi criado com sucesso"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # == update
  #
  # @author Moisés Reis
  #
  # Saves changes to an existing investment fund record.
  def update
    if @investment_fund.update(investment_fund_params.except(:normative_article_ids))
      raw_ids = params.dig(:investment_fund, :normative_article_ids)
      article_ids = Array(raw_ids).map(&:to_s).reject(&:blank?)
      @investment_fund.investment_fund_articles.where.not(normative_article_id: article_ids).destroy_all
      article_ids.each do |article_id|
        @investment_fund.investment_fund_articles.find_or_create_by(normative_article_id: article_id)
      end
      redirect_to @investment_fund, notice: "O credenciamento de fundo de investimento foi atualizado com sucesso"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # == destroy
  #
  # @author Moisés Reis
  #
  # Permanently removes an investment fund record from the system.
  def destroy
    @investment_fund.destroy
    redirect_to investment_funds_path, notice: "O credenciamento de fundo de investimento foi deletado com sucesso"
  end

  # == lookup
  #
  # @author Moisés Reis
  #
  # Retrieves fund information from an external service based on the CNPJ.
  def lookup
    result = CvmFundLookupService.call(params[:cnpj].to_s)
    render json: result
  end

  # =============================================================
  #                       HELPER UTILITIES
  # =============================================================

  private

  # Retrieves the specific investment fund record from the database.
  def load_investment_fund
    @investment_fund = InvestmentFund.find(params[:id])
  end

  # Checks user permissions for the current fund record operation.
  def authorize_investment_fund
    authorize! :read, @investment_fund if action_name == "show"
    authorize! :manage, @investment_fund if %w[update destroy].include?(action_name)
  end

  # Filters parameters allowed for saving investment fund data.
  def investment_fund_params
    params.require(:investment_fund).permit(
      :fund_name,
      :cnpj,
      :administration_fee,
      :performance_fee,
      :benchmark_index,
      :administrator_name,
      :originator_fund,
      normative_article_ids: []
    )
  end
end