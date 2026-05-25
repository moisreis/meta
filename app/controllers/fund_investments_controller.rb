# Manages CRUD operations and visualization workflows for
# portfolio fund investments.
#
# This controller acts as the HTTP orchestration layer for
# {FundInvestment} resources. Business rules, filtering,
# persistence workflows, and valuation reconstruction are
# delegated to dedicated service and query objects under the
# FundInvestments namespace.
#
# This controller does NOT implement financial calculations
# directly. Valuation logic belongs to specialized query
# objects such as {FundInvestments::MarketValueOnQuery}.
#
# @author Moisés Reis

class FundInvestmentsController < ApplicationController

  # =============================================================
  #                   FILTERS & ERROR HANDLING
  # =============================================================

  # --- FILTERS -------------------------------------------------

  before_action :authenticate_user!

  # --- RESOURCE LOADING ----------------------------------------

  before_action :load_fund_investment, only: %i[
    show
    update
    edit
    destroy
  ]

  # --- AUTHORIZATION -------------------------------------------

  before_action :authorize_fund_investment, only: %i[
    show
    update
    edit
    destroy
  ]

  # --- FORM DEPENDENCIES ---------------------------------------

  before_action :load_form_dependencies, only: %i[
    new
    edit
    create
  ]

  # --- ERROR HANDLING ------------------------------------------

  rescue_from ActiveRecord::RecordNotFound do |e|
    respond_to do |format|
      format.html do
        redirect_to portfolios_path,
                    alert: "Investimento não encontrado."
      end

      format.json do
        render json: { error: e.message },
               status: :not_found
      end
    end
  end

  rescue_from CanCan::AccessDenied do |e|
    respond_to do |format|
      format.html do
        redirect_to portfolios_path,
                    alert: e.message
      end

      format.json do
        render json: { error: e.message },
               status: :forbidden
      end
    end
  end

  rescue_from StandardError do |e|
    Rails.logger.error(
      "[FundInvestmentsController] #{e.class}: #{e.message}\n" \
      "#{e.backtrace.first(5).join("\n")}"
    )

    respond_to do |format|
      format.html do
        redirect_to portfolios_path,
                    alert: "Ocorreu um erro inesperado."
      end

      format.json do
        render json: { error: "Internal server error" },
               status: :internal_server_error
      end
    end
  end

  # =============================================================
  #                  INDEX & VISUALIZATION
  # =============================================================

  # --- INDEX ---------------------------------------------------

  # Displays a searchable and paginated collection of
  # accessible fund investments.
  #
  # Filtering, sorting, pagination, and authorization
  # scoping are delegated to
  # {FundInvestments::IndexQuery}.
  #
  # @return [void]
  def index
    result = FundInvestments::IndexQuery.call(
      params[:q],
      page: params[:page],
      sort: params[:sort],
      direction: params[:direction],
      actor: current_user
    )

    @q = result.search
    @fund_investments = result.records
    @total_items = result.total_items

    respond_to { |f| f.html }
  end

  # --- SHOW ----------------------------------------------------

  # Displays the detailed visualization page for a
  # fund investment.
  #
  # Portfolio metrics, allocations, historical
  # reconstruction, and valuation data are delegated
  # to {FundInvestments::ShowService}.
  #
  # @return [void]
  def show
    @data = FundInvestments::ShowService.call(
      @fund_investment,
      reference_date: Date.current
    )
  end

  # =============================================================
  #                          CREATION
  # =============================================================

  # --- NEW -----------------------------------------------------

  # Renders the creation form for a new fund investment.
  #
  # Supporting collections are loaded through
  # {#load_form_dependencies}.
  #
  # @return [void]
  def new
    @fund_investment = FundInvestment.new
  end

  # --- CREATE --------------------------------------------------

  # Creates a new fund investment associated with the
  # authenticated user.
  #
  # Persistence logic and business validations are
  # delegated to {FundInvestments::CreationService}.
  #
  # @return [void]
  def create
    result = FundInvestments::CreationService.call(
      fund_investment_params,
      actor: current_user
    )

    @fund_investment = result.fund_investment || FundInvestment.new(fund_investment_params)

    if result.success?
      redirect_to @fund_investment.portfolio, notice: "Investimento criado com sucesso."
    else
      load_form_dependencies
      render :new, status: :unprocessable_entity
    end
  end

  # =============================================================
  #                           UPDATE
  # =============================================================

  # --- EDIT ----------------------------------------------------

  # Renders the edition form for an existing
  # fund investment.
  #
  # Supporting collections are loaded through
  # {#load_form_dependencies}.
  #
  # @return [void]
  def edit
  end

  # --- UPDATE --------------------------------------------------

  # Updates an existing fund investment.
  #
  # Persistence workflows and validation rules are
  # delegated to {FundInvestments::UpdateService}.
  #
  # @return [void]
  def update
    result = FundInvestments::UpdateService.call(
      @fund_investment,
      fund_investment_params,
      actor: current_user
    )

    @fund_investment = result.fund_investment

    if result.success? 
      redirect_to @fund_investment.portfolio, notice: "Investimento atualizado com sucesso."
    else
      load_form_dependencies
      render :edit, status: :unprocessable_entity
    end
  end

  # =============================================================
  #                          DELETION
  # =============================================================

  # --- DESTROY -------------------------------------------------

  # Deletes an existing fund investment.
  #
  # Deletion workflows and integrity validation are
  # delegated to {FundInvestments::DeleteService}.
  #
  # @return [void]
  def destroy
    portfolio = @fund_investment.portfolio

    result = FundInvestments::DeleteService.call(
      @fund_investment,
      actor: current_user
    )

    if result.success?
      redirect_to portfolio, notice: "Investimento removido com sucesso."
    else
      redirect_to portfolio, alert: result.error || "Não foi possível remover o investimento."
    end
  end

  # --- DELETE CONFIRMATION -------------------------------------

  # Renders the deletion confirmation page for a
  # fund investment.
  #
  # @return [void]
  def delete
  end

  private

  # =============================================================
  #                      RESOURCE LOADING
  # =============================================================

  # Loads the target fund investment from request parameters.
  #
  # @raise [ActiveRecord::RecordNotFound]
  #   Raised when the investment does not exist.
  #
  # @return [void]
  def load_fund_investment
    @fund_investment = FundInvestment.find(params[:id])
  end

  # =============================================================
  #                        AUTHORIZATION
  # =============================================================

  # Applies authorization rules for the current action.
  #
  # Authorization policies are enforced through CanCanCan.
  #
  # @raise [CanCan::AccessDenied]
  #   Raised when the current user lacks permission.
  #
  # @return [void]
  def authorize_fund_investment
    authorize! :read, @fund_investment if action_name == "show"

    authorize! :manage, @fund_investment if %w[
      update
      destroy
      edit
    ].include?(action_name)
  end

  # =============================================================
  #                      STRONG PARAMETERS
  # =============================================================

  # Defines the permitted parameters for fund
  # investment persistence operations.
  #
  # @return [ActionController::Parameters]
  #   Sanitized parameters allowed for persistence.
  def fund_investment_params
    params.require(:fund_investment).permit(
      :portfolio_id,
      :investment_fund_id,
      :total_invested_value,
      :total_quotas_held,
      :percentage_allocation
    )
  end

  # =============================================================
  #                        QUERY HELPERS
  # =============================================================

  # --- ACCESSIBLE COLLECTIONS ----------------------------------

  # Returns the collection of fund investments accessible
  # to the authenticated user.
  #
  # Related portfolio and investment fund associations
  # are eager-loaded to reduce N+1 query overhead.
  #
  # @return [ActiveRecord::Relation<FundInvestment>]
  #   Authorized investment records for the current user.
  def accessible_fund_investments
    FundInvestment.accessible_to(current_user).includes(:portfolio, :investment_fund)
  end

  # --- HISTORICAL VALUATION ------------------------------------

  # Reconstructs the historical market value for a
  # fund investment on a specific reference date.
  #
  # Historical valuation reconstruction is delegated
  # to {FundInvestments::MarketValueOnQuery}.
  #
  # @return [Object]
  #   Historical valuation query result.
  #
  # @raise [ActiveRecord::RecordNotFound]
  #   Raised when the investment does not exist.
  #
  # @raise [Date::Error]
  #   Raised when the provided date is invalid.
  def market_value_on
    FundInvestments::MarketValueOnQuery.call(
      fund_investment: FundInvestment.find(params[:id]),
      date: Date.parse(params[:date])
    )
  end

  # =============================================================
  #                      FORM DEPENDENCIES
  # =============================================================

  # --- FORM COLLECTIONS ----------------------------------------

  # Loads supporting collections required by creation
  # and edition forms.
  #
  # @return [void]
  def load_form_dependencies
    @investment_funds = InvestmentFund.all
    @portfolios = accessible_portfolios
  end

  # --- ACCESSIBLE PORTFOLIOS -----------------------------------

  # Returns the portfolios accessible to the
  # authenticated user.
  #
  # @return [ActiveRecord::Relation<Portfolio>]
  #   Portfolios owned by the current user.
  def accessible_portfolios
    current_user.portfolios
  end
end