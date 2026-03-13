# === redemptions_controller.rb
#
# Description:: Manages the lifecycle of investment redemptions within the system,
#               handling the calculation of quotas, FIFO allocation, and financial
#               balance updates across portfolios.
#
# Usage:: - *What* - This controller serves as the primary interface for creating,
#           tracking, and removing redemption records for fund investments.
#         - *How* - It integrates with PDF generation, utilizes Ransack for filtering,
#           and employs database transactions to ensure quota integrity during allocation.
#         - *Why* - Accurate redemption tracking is essential for calculating portfolio
#           returns, maintaining tax records, and ensuring the correct balance of held quotas.
#
# Attributes:: - *@redemptions* [Collection] - A paginated list of redemption records.
#              - *@redemption* [Object] - The specific redemption record being viewed or modified.
#              - *@fund_investments* [Collection] - Available investments used for populating forms.
#
class RedemptionsController < ApplicationController

  # =============================================================
  #                        CONFIGURATION
  # =============================================================

  # Includes the shared logic for exporting data into structured PDF documents.
  # This module provides the interface needed to generate reports from records.
  include PdfExportable

  # Defines the list of database columns that are permitted for sorting operations.
  # This ensures that only valid fields are used in the SQL order clause.
  REDEMPTIONS_ALLOWED_SORT_COLUMNS = %w[request_date cotization_date liquidation_date redeemed_liquid_value redeemed_quotas].freeze

  # Defines the allowed directions for ordering the retrieved records.
  # This restricts sorting to either ascending or descending order.
  REDEMPTIONS_ALLOWED_DIRECTIONS = %w[asc desc].freeze

  # Validates that a user is signed in before allowing access to any action.
  # It protects the routes by redirecting unauthenticated visitors to login.
  before_action :authenticate_user!

  # Retrieves the list of investments the user can access to populate selection menus.
  # This runs before actions that require the user to choose an investment fund.
  before_action :load_form_collections, only: %i[new create edit update]

  # Finds a specific redemption record from the database before performing updates or deletions.
  # This simplifies the controller actions by setting the @redemption variable early.
  before_action :load_redemption, only: %i[show edit update destroy]

  # Verifies that the user has the required permissions to manage the specific redemption.
  # It checks if the current user is authorized to perform actions on the related portfolio.
  before_action :authorize_redemption, only: %i[show update destroy]

  # =============================================================
  #                       ERROR HANDLING
  # =============================================================

  # Redirects the user and shows an alert when a requested record is not found.
  # This prevents the application from crashing when a record ID does not exist.
  rescue_from ActiveRecord::RecordNotFound do |e|
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: "Registro não encontrado." }
      format.json { render json: { error: e.message }, status: :not_found }
    end
  end

  # Handles cases where the user attempts to access data they do not have permission for.
  # This provides a graceful exit and a feedback message when authorization fails.
  rescue_from CanCan::AccessDenied do |e|
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: e.message }
      format.json { render json: { error: e.message }, status: :forbidden }
    end
  end

  # Catches unexpected server errors, logs the details, and provides a generic error message.
  # This maintains a professional user experience even when an unhandled exception occurs.
  rescue_from StandardError do |e|
    Rails.logger.error("[RedemptionsController] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
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
  # Lists all redemptions related to investments the user is authorized to see.
  # It provides filtering through search parameters and handles pagination for the view.
  def index
    # Filters investment IDs based on what the current user is allowed to access.
    # This acts as a security layer to ensure data privacy between users.
    fund_investment_ids = FundInvestment.accessible_to(current_user).select(:id)

    # Builds the base scope for redemptions including associated data to avoid N+1 queries.
    # It ensures that portfolios and investment funds are loaded efficiently.
    base_scope = Redemption
                   .where(fund_investment_id: fund_investment_ids)
                   .includes(fund_investment: [:portfolio, :investment_fund])

    # Initializes the Ransack search object with the provided query parameters.
    # This allows users to filter the redemption list by dates or values.
    @q = base_scope.ransack(params[:q])

    # Executes the query and ensures that the results are unique.
    # This prevents duplicate records from appearing when joining multiple tables.
    filtered = @q.result(distinct: true)

    # Calculates the total number of items found after applying filters.
    # This value is typically used to display record counts in the interface.
    @total_items = filtered.count

    # Validates and sets the sort column based on permitted attributes.
    # It defaults to the request date if no valid column is provided.
    sort = REDEMPTIONS_ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "request_date"

    # Validates and sets the sort direction based on permitted values.
    # It defaults to descending order to show the most recent records first.
    direction = REDEMPTIONS_ALLOWED_DIRECTIONS.include?(params[:direction]) ? params[:direction] : "desc"

    # Applies sorting and pagination to the final collection of redemptions.
    # The results are limited to a specific number of items per page.
    @redemptions = filtered.order("#{sort} #{direction}").page(params[:page]).per(14)

    respond_to { |f| f.html }
  end

  # == show
  #
  # @author Moisés Reis
  #
  # Displays the specific details of a single redemption record.
  # It relies on the pre-loaded @redemption variable to render the view.
  def show
  end

  # == new
  #
  # @author Moisés Reis
  #
  # Prepares a new redemption instance for the creation form.
  # This provides the empty object needed to build the form helpers in the view.
  def new
    @redemption = Redemption.new
  end

  # == create
  #
  # @author Moisés Reis
  #
  # Calculates necessary quotas, validates availability, and saves the redemption.
  # It updates portfolio balances and triggers a recalculation in a single transaction.
  def create

    # Initializes a new redemption object with the permitted request parameters.
    # This object is checked for validity before any database changes are made.
    @redemption = Redemption.new(redemption_params)

    # Retrieves the associated fund investment record for processing.
    # This is used to verify permissions and check available quota balances.
    fund_investment = @redemption.fund_investment

    # Checks if the fund investment exists and adds an error if it is missing.
    # This prevents the process from continuing with invalid association data.
    unless fund_investment
      @redemption.errors.add(:fund_investment_id, "não encontrado")
      return render :new, status: :unprocessable_entity
    end

    # Verifies that the user has management permissions for the target portfolio.
    # This is a critical security check to prevent unauthorized financial operations.
    authorize! :manage, fund_investment.portfolio

    # Calculates the amount of quotas being redeemed based on the liquid value.
    # It handles both total redemptions and partial value-based calculations.
    if @redemption.cotization_date.present? && @redemption.redeemed_liquid_value.present?
      if @redemption.redemption_type == "total"

        # For total redemptions, all currently held quotas are used.
        # This simplifies the process by ignoring partial value fluctuations.
        @redemption.redeemed_quotas = fund_investment.total_quotas_held
      else
        # For partial redemptions, it finds the quota value for the specific date.
        # This determines how many units must be sold to reach the requested value.
        quota_value = fund_investment.investment_fund.quota_value_on(@redemption.cotization_date)

        # Prevents the redemption if no quota valuation is found for the date.
        # This ensures that calculations are always based on official market data.
        unless quota_value
          @redemption.errors.add(:base, "Sem cota disponível para esta data.")
          return render :new, status: :unprocessable_entity
        end

        @redemption.redeemed_quotas = BigDecimal(@redemption.redeemed_liquid_value.to_s) / quota_value
      end
    end

    # Checks if the requested quota amount exceeds what is currently held.
    # This prevents users from redeeming more than they actually own.
    if (@redemption.redeemed_quotas || 0) > (fund_investment.total_quotas_held || 0)
      @redemption.errors.add(:base, "Cotas insuficientes: disponível #{fund_investment.total_quotas_held}.")
      return render :new, status: :unprocessable_entity
    end

    # Executes the saving and recalculation logic inside a database transaction.
    # This ensures that all updates succeed or fail together, maintaining integrity.
    ActiveRecord::Base.transaction do

      # Saves the redemption record and triggers model-level validations.
      # If validations fail, the transaction will roll back automatically.
      @redemption.save!

      # Distributes the redeemed quotas across specific acquisition events.
      # This follows a FIFO logic to track which shares were sold and at what cost.
      allocate_quotas_fifo(fund_investment, @redemption.redeemed_quotas)

      # Calculates the proportional investment cost of the redeemed quotas.
      # This is used to adjust the total invested value without dipping into negatives.
      value_delta = if fund_investment.total_quotas_held > 0
                      proportion = BigDecimal(@redemption.redeemed_quotas.to_s) /
                                   BigDecimal(fund_investment.total_quotas_held.to_s)
                      -(proportion * fund_investment.total_invested_value)
                    else
                      BigDecimal("0")
                    end

      # Updates the cached balances on the fund investment record.
      # This reflects the new total of quotas and the adjusted invested value.
      fund_investment.update_balances!(
        quotas_delta: -@redemption.redeemed_quotas,
        value_delta: value_delta
      )

      # Triggers a recalculation of the entire portfolio allocation.
      # This ensures that charts and summaries reflect the latest redemption.
      PortfolioAllocationCalculator.recalculate!(fund_investment.portfolio)
    end

    redirect_to fund_investment_path(fund_investment), notice: "Resgate criado com sucesso."

  rescue ActiveRecord::RecordInvalid => e

    # Captures validation errors during the transaction and returns to the form.
    # This allows the user to correct input mistakes while seeing specific errors.
    @redemption = e.record
    render :new, status: :unprocessable_entity
  end

  # == edit
  #
  # @author Moisés Reis
  #
  # Loads the editing interface for an existing redemption.
  # It provides the form where users can modify the details of a previous record.
  def edit
  end

  # == update
  #
  # @author Moisés Reis
  #
  # Updates the attributes of an existing redemption and redirects to its detail page.
  # This handles the persistence of changes made through the edit form.
  def update
    if @redemption.update(redemption_params)
      redirect_to redemption_path(@redemption), notice: "Resgate atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # == destroy
  #
  # @author Moisés Reis
  #
  # Deletes a redemption, restores the consumed quotas, and recalculates balances.
  # It effectively reverses the financial impact of the redemption record.
  def destroy

    # Identifies the fund investment to update after the record is removed.
    # This reference is held to ensure the balances are corrected post-deletion.
    fund_investment = @redemption.fund_investment

    # Wraps the deletion and restoration in a transaction for data safety.
    # This prevents partial deletions where quotas are lost but the record is gone.
    ActiveRecord::Base.transaction do

      # Restores the quotas to the specific applications they were taken from.
      # This maintains the historical accuracy of the FIFO allocation chain.
      revert_quotas_on_destroy(fund_investment)

      # Permanently removes the redemption record from the database.
      # This action cannot be undone once the transaction is committed.
      @redemption.destroy!

      # Forces a recalculation of the portfolio to reflect the restored values.
      # This ensures that the user sees the updated balance immediately.
      PortfolioAllocationCalculator.recalculate!(fund_investment.portfolio)
    end

    respond_to do |format|
      format.html { redirect_to fund_investment_path(fund_investment), notice: "Resgate deletado com sucesso.", status: :see_other }
      format.json { render json: { status: "Success", message: "Resgate deletado com sucesso." }, status: :ok }
    end

  rescue ActiveRecord::RecordInvalid => e

    # Handles cases where the database cannot safely remove or update records.
    # It provides feedback to the user if the deletion process is blocked.
    respond_to do |format|
      format.html { redirect_to redemption_path(@redemption), alert: "Falha ao deletar resgate." }
      format.json { render json: { status: "Error", errors: e.record.errors.full_messages }, status: :unprocessable_entity }
    end
  rescue CanCan::AccessDenied => e

    # Ensures that only authorized users can delete redemption records.
    # This prevents malicious or accidental deletions by unauthorized accounts.
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: e.message }
      format.json { render json: { status: "Error", message: e.message }, status: :forbidden }
    end
  end

  # =============================================================
  #                       PRIVATE METHODS
  # =============================================================

  private

  # Retrieves the specific redemption from the database by its unique identifier.
  # It uses the ID parameter provided in the URL to locate the record.
  def load_redemption
    @redemption = Redemption.find(params[:id])
  end

  # Fetches all fund investments the user is allowed to access for form selection.
  # It includes associations to prevent multiple database hits during rendering.
  def load_form_collections
    @fund_investments = FundInvestment
                          .accessible_to(current_user)
                          .includes(:investment_fund, :portfolio)
  end

  # Ensures the user has permission to manage the portfolio associated with the redemption.
  # This uses the authorization library to check the user's role and ownership.
  def authorize_redemption
    authorize! :manage, @redemption.fund_investment.portfolio
  end

  # Defines the strict list of parameters allowed to be modified through requests.
  # This follows the Strong Parameters pattern to prevent mass-assignment attacks.
  def redemption_params
    params.require(:redemption).permit(
      :fund_investment_id,
      :request_date,
      :redeemed_liquid_value,
      :redeemed_quotas,
      :redemption_yield,
      :redemption_type,
      :cotization_date,
      :liquidation_date
    )
  end

  # == allocate_quotas_fifo
  #
  # @author Moisés Reis
  #
  # Distributes the redeemed amount across existing applications using a
  # First-In, First-Out (FIFO) approach to track quota usage correctly.
  def allocate_quotas_fifo(fund_investment, remaining_quotas)

    # Retrieves all applications for this investment that still have quotas available.
    # It orders them by cotization date to ensure the oldest are processed first.
    applications = fund_investment.applications
                                  .includes(:redemption_allocations)
                                  .where("number_of_quotas > 0")
                                  .order(:cotization_date)

    applications.each do |app|

      # Stops the process once all requested quotas have been allocated.
      # This prevents the loop from consuming more applications than necessary.
      break if remaining_quotas <= 0

      # Checks how many quotas are still free to be used in this specific application.
      # It skips records that have already been fully redeemed.
      available = app.available_quotas
      next if available <= 0

      # Determines the amount to use from the current application.
      # It takes either the available amount or the remaining need, whichever is smaller.
      quotas_to_use = [available, remaining_quotas].min

      # Creates a join record that links this redemption to the specific application.
      # This record stores how many quotas were taken from this particular investment event.
      RedemptionAllocation.create!(
        redemption: @redemption,
        application: app,
        quotas_used: quotas_to_use
      )

      # Subtracts the used amount from the total remaining to be allocated.
      # This value continues to decrease until the loop finishes or hits zero.
      remaining_quotas -= quotas_to_use
    end
  end

  # == revert_quotas_on_destroy
  #
  # @author Moisés Reis
  #
  # Restores quotas to their source applications when a redemption is deleted.
  # This maintains accurate historical and current balance records by reversing changes.
  def revert_quotas_on_destroy(fund_investment)

    # Gathers all allocations associated with the redemption being deleted.
    # It includes the application details to restore values correctly.
    allocations = @redemption.redemption_allocations.includes(:application)

    # Calculates the total financial value to be restored based on historical costs.
    # This ensures the invested value returns to its state before the redemption.
    reverted_value = allocations.sum { |a| a.quotas_used * a.application.quota_value_at_application }

    allocations.each do |allocation|
      # References the specific application record that provided the quotas.
      # This allows the system to add the units back to the correct bucket.
      app = allocation.application

      # Updates the application to include the returned quotas and financial value.
      # This effectively "un-sells" the units in the system's tracking.
      app.update!(
        number_of_quotas: app.number_of_quotas + allocation.quotas_used,
        financial_value: app.financial_value + (allocation.quotas_used * app.quota_value_at_application)
      )
    end

    # Updates the investment's cached totals with the restored quantities.
    # This reflects the increase in both quotas and invested value.
    fund_investment.update_balances!(
      quotas_delta: allocations.sum(:quotas_used),
      value_delta: reverted_value
    )
  end

  # Sets the main title used for PDF exports.
  # This string appears as the primary heading in the generated document.
  def pdf_export_title = "Resgates"

  # Sets the descriptive subtitle used for PDF exports.
  # This provides additional context below the main title in the report.
  def pdf_export_subtitle = "Histórico de resgates realizados"

  # == pdf_export_columns
  #
  # @author Moisés Reis
  #
  # Defines the column structure, data formatting, and sizing for the PDF table.
  # It specifies how each attribute should be displayed to the user in the report.
  def pdf_export_columns
    # Accesses standard Rails view helpers for formatting currency and numbers.
    # This ensures that values in the PDF match the formatting used in the web UI.
    h = ActionController::Base.helpers

    [
      { header: "Data Solicitação", key: ->(r) { r.request_date ? I18n.l(r.request_date, format: :short) : "N/A" }, width: 85 },
      { header: "Data Cotização", key: ->(r) { r.cotization_date ? I18n.l(r.cotization_date, format: :short) : "N/A" }, width: 85 },
      { header: "Fundo", key: ->(r) { r.fund_investment.investment_fund.fund_name }, width: 150 },
      { header: "Carteira", key: ->(r) { r.fund_investment.portfolio.name }, width: 100 },
      { header: "Tipo", key: ->(r) { r.redemption_type&.capitalize || "N/A" }, width: 60 },
      {
        header: "Cotas Resgatadas",
        key: ->(r) { h.number_with_precision(r.redeemed_quotas, precision: 2, separator: ",", delimiter: ".") },
        width: 90
      },
      {
        header: "Valor Líquido",
        key: ->(r) { h.number_to_currency(r.redeemed_liquid_value, unit: "R$ ", separator: ",", delimiter: ".") },
        width: 90
      },
      {
        header: "Rendimento",
        key: ->(r) { r.redemption_yield ? h.number_to_currency(r.redemption_yield, unit: "R$ ", separator: ",", delimiter: ".") : "N/A" },
        width: 80
      }
    ]
  end

  # == pdf_export_data
  #
  # @author Moisés Reis
  #
  # Fetches and sorts the specific data points that will be rendered in the PDF export.
  # It applies the same filters and authorization rules as the index view.
  def pdf_export_data

    # Identifies the investments accessible to the current user.
    # This limits the report data to only what the user is permitted to see.
    fund_investment_ids = FundInvestment.accessible_to(current_user).select(:id)

    # Sets up the base query scope with necessary relations for the table.
    # It ensures that fund and portfolio names can be retrieved efficiently.
    base_scope = Redemption
                   .where(fund_investment_id: fund_investment_ids)
                   .includes(fund_investment: [:portfolio, :investment_fund])

    # Re-applies the search filters to ensure the PDF matches the filtered view.
    # This keeps the exported document consistent with what the user sees on screen.
    @q = base_scope.ransack(params[:q])

    # Determines the sort order for the PDF based on parameters or defaults.
    # It prevents SQL injection by validating against a whitelist of columns.
    sort = REDEMPTIONS_ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "request_date"
    direction = REDEMPTIONS_ALLOWED_DIRECTIONS.include?(params[:direction]) ? params[:direction] : "desc"

    @q.result(distinct: true).order("#{sort} #{direction}")
  end

  # == pdf_export_metadata
  #
  # @author Moisés Reis
  #
  # Compiles high-level summary information, such as totals and user details, for the PDF header.
  # This provides a quick financial overview at the beginning of the document.
  def pdf_export_metadata

    # Accesses helpers for formatting money and large numbers in the metadata.
    # It allows for clear display of total values and quota counts.
    h = ActionController::Base.helpers

    # Retrieves the dataset being exported to calculate total sums.
    # This ensures the metadata matches the records listed in the table.
    data = pdf_export_data

    {
      "Usuário" => current_user.full_name,
      "E-mail" => current_user.email,
      "Total de resgates" => data.size.to_s,
      "Valor total resgatado" => h.number_to_currency(data.sum(:redeemed_liquid_value), unit: "R$ ", separator: ",", delimiter: "."),
      "Cotas totais resgatadas" => h.number_with_precision(data.sum(:redeemed_quotas), precision: 2, separator: ",", delimiter: ".")
    }
  end
end