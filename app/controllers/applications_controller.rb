# =============================================================
#                CONFIGURATION & DEPENDENCIES
# =============================================================
# This section defines the security constants used for sorting
# and filtering data to prevent unauthorized database queries.

# These constants define which columns and directions are safe
# for the system to use when organizing the application lists.
APPLICATIONS_ALLOWED_SORT_COLUMNS = %w[request_date cotization_date liquidation_date financial_value].freeze

# This list determines the valid ways to order the data, such
# as starting from the newest or oldest investment entry.
APPLICATIONS_ALLOWED_DIRECTIONS = %w[asc desc].freeze

# === applications_controller.rb
#
# Description:: Manages the lifecycle of investment applications within the system.
#               It handles the creation, viewing, and deletion of investments while
#               ensuring all financial balances and portfolios stay updated.
#
# Usage:: - *What* - A controller that acts as the primary interface for recording
#           new money entering an investment fund.
#         - *How* - It validates user permissions via +CanCan+ and performs
#           automatic financial calculations for quotas and portfolio totals.
#         - *Why* - Centralizing this logic ensures that every investment record
#           is accurate and that users only access data they are allowed to see.
#
# Attributes:: - *@application* [Application] - The specific investment record
#                being viewed, created, or managed.
#              - *@q* [Ransack::Search] - The search object used to filter
#                and sort the list of applications.
#              - *@fund_investments* [Enumerable] - A collection of available
#                funds linked to the user's portfolios for selection.
#
# View:: - +PortfoliosView+
#
# Notes:: This file relies on +PortfolioAllocationCalculator+ to update the
#         overall health and distribution of assets after every change.
class ApplicationsController < ApplicationController

  # These instructions run before any page loads to ensure the
  # user is logged in and has the right permissions for the data.
  before_action :authenticate_user!

  # This ensures the specific investment record is found in the
  # database before a user tries to view, edit, or delete it.
  before_action :load_application, only: %i[show edit update destroy]

  # This security check confirms the user actually owns or manages
  # the portfolio associated with the investment they are accessing.
  before_action :authorize_application, only: %i[show edit update destroy]

  # This gathers the necessary lists of funds and portfolios
  # needed to populate dropdown menus in the investment forms.
  before_action :load_form_dependencies, only: %i[new edit create]

  # =============================================================
  #                        ERROR HANDLING
  # =============================================================
  # This group of rules catches common mistakes or security blocks
  # and redirects the user to a safe page with a helpful message.

  # This catches cases where a user tries to access an investment
  # that does not exist or has been deleted from the system.
  rescue_from ActiveRecord::RecordNotFound do |e|
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: "Registro não encontrado." }
      format.json { render json: { error: e.message }, status: :not_found }
    end
  end

  # This handles situations where a user tries to access data
  # that belongs to someone else or is restricted by their role.
  rescue_from CanCan::AccessDenied do |e|
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: e.message }
      format.json { render json: { error: e.message }, status: :forbidden }
    end
  end

  # This acts as a safety net for any unexpected system errors,
  # logging the technical details while showing a simple message.
  rescue_from StandardError do |e|
    Rails.logger.error("[ApplicationsController] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: "Ocorreu um erro inesperado." }
      format.json { render json: { error: "Internal server error" }, status: :internal_server_error }
    end
  end

  # =============================================================
  #                       PUBLIC METHODS
  # =============================================================
  # These methods represent the main actions a user can take,
  # such as listing all investments or adding a new one.

  # == index
  #
  # @author Moisés Reis
  #
  # This action gathers all investment applications the user
  # is allowed to see and prepares them for a searchable list.
  #
  # Returns:: - A paginated list of applications sorted by the user's choice.
  def index

    # This finds all the investment connections associated with
    # the portfolios the current user is authorized to manage.
    fund_investment_ids = FundInvestment.accessible_to(current_user).select(:id)

    # This creates the starting point for the list, including
    # related details like portfolio names to avoid extra loading.
    base_scope = Application
                   .where(fund_investment_id: fund_investment_ids)
                   .includes(fund_investment: [:portfolio, :investment_fund])

    # This applies any search filters the user has typed in
    # and counts the total items found to display in the UI.
    @q = base_scope.ransack(params[:q])
    filtered = @q.result(distinct: true)

    @total_items = filtered.count

    # This determines how the list should be ordered, falling
    # back to a default date order if no preference is provided.
    sort = APPLICATIONS_ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "request_date"
    direction = APPLICATIONS_ALLOWED_DIRECTIONS.include?(params[:direction]) ? params[:direction] : "desc"

    # This finalizes the list by limiting it to 14 items per
    # page to keep the screen clean and fast to load.
    @applications = filtered.order("#{sort} #{direction}").page(params[:page]).per(14)

    respond_to { |f| f.html }
  end

  # == show
  #
  # @author Moisés Reis
  #
  # This action displays the full details of a single investment,
  # including performance metrics and data consistency checks.
  #
  # Returns:: - A detailed view of a specific investment application.
  def show
    prepare_application_metrics
    respond_to { |f| f.html }
  end

  # == new
  #
  # @author Moisés Reis
  #
  # This action prepares a blank form so the user can start
  # entering the details for a brand new investment.
  #
  # Returns:: - An empty application object ready for the form.
  def new
    @application = Application.new
  end

  # == edit
  #
  # @author Moisés Reis
  #
  # This action opens an existing investment record for modification,
  # though certain updates may be restricted to ensure data integrity.
  #
  # Returns:: - An existing application object for the editing form.
  def edit
  end

  # == create
  #
  # @author Moisés Reis
  #
  # This process saves a new investment to the database, creates
  # fund links if they don't exist, and updates portfolio totals.
  #
  # Returns:: - A redirect to the portfolio page on success or the form on failure.
  def create

    # This retrieves the target portfolio and fund using the
    # information provided in the user's submitted form.
    portfolio = Portfolio.find(application_params[:portfolio_id])
    fund = InvestmentFund.find(application_params[:investment_fund_id])

    # This verifies the user has the authority to add new
    # investments to the selected portfolio before proceeding.
    authorize! :manage, portfolio

    # This ensures a connection exists between the portfolio
    # and the fund, creating one with zero balance if needed.
    fund_investment = FundInvestment.find_or_create_by!(
      investment_fund: fund,
      portfolio: portfolio
    ) do |fi|
      fi.skip_allocation_validation = true
      fi.percentage_allocation = 0
      fi.total_invested_value = 0
      fi.total_quotas_held = 0
    end

    # This builds the new investment record while linking it
    # to the specific portfolio-fund connection established above.
    @application = Application.new(
      application_params.except(:portfolio_id, :investment_fund_id)
                        .merge(fund_investment: fund_investment)
    )

    # This calculates how many shares (quotas) the money bought
    # based on the fund's value on the day of the investment.
    if @application.cotization_date.present? && @application.financial_value.present?
      quota_value = fund.quota_value_on(@application.cotization_date)

      unless quota_value
        @application.errors.add(:cotization_date, "Não há cota disponível para esta data")
        return render :new, status: :unprocessable_entity
      end

      @application.quota_value_at_application = quota_value
      @application.number_of_quotas = BigDecimal(@application.financial_value.to_s) / quota_value
    end

    # This saves the investment and updates all balances in a
    # single step so that the data remains consistent if an error occurs.
    ActiveRecord::Base.transaction do
      @application.save!
      fund_investment.update_balances!(
        quotas_delta: @application.number_of_quotas || 0,
        value_delta: @application.financial_value || 0
      )
      PortfolioAllocationCalculator.recalculate!(portfolio)
    end

    flash[:notice] = "Investimento criado com sucesso."
    redirect_to portfolio_path(portfolio)

  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Application save failed: #{e.record.errors.full_messages}"
    @application ||= Application.new
    render :new, status: :unprocessable_entity
  rescue CanCan::AccessDenied
    redirect_to portfolios_path
  end

  # == update
  #
  # @author Moisés Reis
  #
  # This action is currently disabled to prevent users from
  # changing financial data that has already been calculated.
  #
  # Returns:: - An error status indicating this action is not allowed.
  # == update
  #
  # @author Moisés Reis
  #
  # Corrige os dados de uma aplicação lançada com valor errado.
  # Recalcula cotas automaticamente a partir da cota do fundo na data de cotização,
  # valida que as cotas não retrocedam abaixo do já alocado em resgates,
  # e ajusta os saldos do FundInvestment via delta para não dupla-contar.
  def update
    fund_investment = @application.fund_investment

    # Snapshot dos valores atuais *antes* de qualquer atribuição.
    # Necessário para calcular o delta que será aplicado ao FundInvestment.
    old_value  = @application.financial_value  || BigDecimal("0")
    old_quotas = @application.number_of_quotas || BigDecimal("0")

    @application.assign_attributes(
      application_params.except(:portfolio_id, :investment_fund_id, :fund_investment_id)
    )

    # Se há data de cotização e valor financeiro, recalcula cotas e valor unitário
    # a partir da tabela de valuations — mesmo fluxo do create.
    if @application.cotization_date.present? && @application.financial_value.present?
      quota_value = fund_investment.investment_fund.quota_value_on(@application.cotization_date)

      unless quota_value
        @application.errors.add(:cotization_date, "não há cota disponível para esta data")
        return render :edit, status: :unprocessable_entity
      end

      @application.quota_value_at_application = quota_value
      @application.number_of_quotas = BigDecimal(@application.financial_value.to_s) / quota_value
    end

    # Guarda: não permite reduzir cotas abaixo do que já foi alocado em resgates.
    # Sem esse check, RedemptionAllocations existentes passariam a exceder o saldo.
    already_allocated = @application.redemption_allocations.sum(:quotas_used)
    new_quotas        = @application.number_of_quotas || BigDecimal("0")

    if new_quotas < already_allocated
      @application.errors.add(
        :number_of_quotas,
        "não pode ser menor que as cotas já alocadas em resgates (#{already_allocated.round(6)})"
      )
      return render :edit, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      @application.save!

      # Aplica apenas a diferença (delta) para não dupla-contar com o valor
      # original que já estava somado no FundInvestment.
      value_delta  = (@application.financial_value  || BigDecimal("0")) - old_value
      quotas_delta = (@application.number_of_quotas || BigDecimal("0")) - old_quotas

      if value_delta.nonzero? || quotas_delta.nonzero?
        fund_investment.update_balances!(
          quotas_delta: quotas_delta,
          value_delta:  value_delta
        )
      end

      PortfolioAllocationCalculator.recalculate!(fund_investment.portfolio)
    end

    redirect_to application_path(@application), notice: "Aplicação atualizada com sucesso."

  rescue ActiveRecord::RecordInvalid => e
    @application = e.record
    render :edit, status: :unprocessable_entity
  end

  # == destroy
  #
  # @author Moisés Reis
  #
  # This action removes an investment from the records and
  # subtracts its values from the portfolio's total balance.
  #
  # Returns:: - A redirect to the fund view after the record is removed.
  def destroy
    fund_investment = @application.fund_investment

    # This performs the deletion and balance adjustment inside
    # a transaction to ensure no money is "lost" or "doubled."
    ActiveRecord::Base.transaction do
      fund_investment.update_balances!(
        quotas_delta: -(@application.number_of_quotas || 0),
        value_delta: -(@application.financial_value || 0)
      )
      @application.destroy!
      PortfolioAllocationCalculator.recalculate!(fund_investment.portfolio)
    end

    flash[:notice] = "Investimento deletado com sucesso."
    redirect_to fund_investment_path(fund_investment.id), status: :see_other

  rescue ActiveRecord::RecordInvalid
    redirect_to application_path(@application)
  end

  # =============================================================
  #                       PRIVATE METHODS
  # =============================================================
  # These helper methods perform internal tasks like loading
  # data or checking permissions and are not accessed directly.

  private

  # This finds a specific investment by its ID number so
  # the controller can display or modify it.
  def load_application
    @application = Application.find(params[:id])
  end

  # This loads the list of funds the user can choose from
  # when they are filling out the investment form.
  def load_form_dependencies
    @fund_investments = FundInvestment
                          .accessible_to(current_user)
                          .includes(:portfolio, :investment_fund)
  end

  # This checks if the user has permission to manage the
  # portfolio that owns the specific investment record.
  def authorize_application
    authorize! :manage, @application.fund_investment.portfolio
  end

  # This defines which fields from the user's form are safe
  # to save to the database, preventing unauthorized data entry.
  def application_params
    params.require(:application).permit(
      :portfolio_id,
      :investment_fund_id,
      :fund_investment_id,
      :request_date,
      :financial_value,
      :number_of_quotas,
      :quota_value_at_application,
      :cotization_date,
      :liquidation_date
    )
  end

  # This method converts dates entered in the Brazilian format
  # (DD/MM/YYYY) into a format the database can understand.
  def parsed_date_params
    date_fields = %i[request_date cotization_date liquidation_date]
    raw = params.require(:application)

    date_fields.each_with_object({}) do |field, hash|
      raw_value = raw[field].presence
      next unless raw_value

      parsed = parse_br_date(raw_value)
      hash[field] = parsed if parsed
    end
  end

  # This handles the logic for breaking apart a date string
  # and transforming it into a proper calendar date object.
  def parse_br_date(value)
    return value unless value.match?(%r{\A\d{2}/\d{2}/\d{4}\z})

    day, month, year = value.split("/")
    Date.new(year.to_i, month.to_i, day.to_i).iso8601
  rescue ArgumentError
    nil
  end

  # This method calculates complex stats for the show page,
  # like how much of the investment has already been withdrawn.
  def prepare_application_metrics

    # This calculates the percentage of the investment that
    # has been used for redemptions or other transactions.
    allocated_quotas = @application.redemption_allocations.sum(:quotas_used) || 0

    @allocation_percentage =
      if @application.number_of_quotas.to_f.positive?
        (allocated_quotas.to_f / @application.number_of_quotas.to_f) * 100
      else
        0
      end

    # This counts the number of days between the request
    # and when the money was actually processed and moved.
    @processing_days =
      if @application.request_date && @application.liquidation_date
        (@application.liquidation_date - @application.request_date).to_i
      end

    @calculated_quota_value = @application.calculated_quota_value
    @stored_quota_value = @application.quota_value_at_application

    # This checks if the value saved in the record matches
    # the value calculated by the system to ensure accuracy.
    @is_quota_consistent =
      @calculated_quota_value &&
      @stored_quota_value &&
      (@calculated_quota_value - @stored_quota_value).abs <= 0.01

    # This validates that the sequence of dates makes sense
    # (e.g., you can't process an investment before it is requested).
    @cotization_valid =
      !@application.cotization_date ||
      !@application.request_date ||
      @application.cotization_date >= @application.request_date

    @liquidation_valid =
      !@application.liquidation_date ||
      !@application.cotization_date ||
      @application.liquidation_date >= @application.cotization_date

    # This ensures that the financial values provided are
    # positive numbers and not negative or zero.
    @positive_values =
      @application.financial_value.to_f.positive? &&
      (@application.number_of_quotas.nil? || @application.number_of_quotas.to_f.positive?)

    # This sets a visual status indicator so the user can
    # quickly see if the investment data is healthy or not.
    @quota_consistency_status =
      if @is_quota_consistent
        :success
      elsif @calculated_quota_value.present?
        :alert
      else
        :default
      end
  end
end