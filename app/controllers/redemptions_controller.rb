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
  include PdfExportable

  # Defines the list of database columns that are permitted for sorting operations.
  REDEMPTIONS_ALLOWED_SORT_COLUMNS = %w[request_date cotization_date liquidation_date redeemed_liquid_value redeemed_quotas].freeze

  # Defines the allowed directions for ordering the retrieved records.
  REDEMPTIONS_ALLOWED_DIRECTIONS = %w[asc desc].freeze

  # Validates that a user is signed in before allowing access to any action.
  before_action :authenticate_user!

  # Retrieves the list of investments the user can access to populate selection menus.
  before_action :load_form_collections, only: %i[new create edit update]

  # Finds a specific redemption record from the database before performing updates or deletions.
  before_action :load_redemption, only: %i[show edit update destroy]

  # Verifies that the user has the required permissions to manage the specific redemption.
  before_action :authorize_redemption, only: %i[show update destroy]

  # =============================================================
  #                       ERROR HANDLING
  # =============================================================

  # Redirects the user and shows an alert when a requested record is not found.
  rescue_from ActiveRecord::RecordNotFound do |e|
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: "Registro não encontrado." }
      format.json { render json: { error: e.message }, status: :not_found }
    end
  end

  # Handles cases where the user attempts to access data they do not have permission for.
  rescue_from CanCan::AccessDenied do |e|
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: e.message }
      format.json { render json: { error: e.message }, status: :forbidden }
    end
  end

  # Catches unexpected server errors, logs the details, and provides a generic error message.
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
  # Lists all redemptions related to investments the user is authorized to see,
  # including search and sorting capabilities.
  def index
    fund_investment_ids = FundInvestment.accessible_to(current_user).select(:id)

    base_scope = Redemption
                   .where(fund_investment_id: fund_investment_ids)
                   .includes(fund_investment: [:portfolio, :investment_fund])

    @q = base_scope.ransack(params[:q])
    filtered = @q.result(distinct: true)

    @total_items = filtered.count

    sort = REDEMPTIONS_ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "request_date"
    direction = REDEMPTIONS_ALLOWED_DIRECTIONS.include?(params[:direction]) ? params[:direction] : "desc"

    @redemptions = filtered.order("#{sort} #{direction}").page(params[:page]).per(14)

    respond_to { |f| f.html }
  end

  # == show
  #
  # @author Moisés Reis
  #
  # Displays the specific details of a single redemption record.
  def show
  end

  # == new
  #
  # @author Moisés Reis
  #
  # Prepares a new redemption instance for the creation form.
  def new
    @redemption = Redemption.new
  end

  # == create
  #
  # @author Moisés Reis
  #
  # Calculates necessary quotas, validates availability, and saves the redemption
  # while updating portfolio balances in a single transaction.
  def create
    @redemption = Redemption.new(redemption_params)
    fund_investment = @redemption.fund_investment

    unless fund_investment
      @redemption.errors.add(:fund_investment_id, "não encontrado")
      return render :new, status: :unprocessable_entity
    end

    authorize! :manage, fund_investment.portfolio

    # Após calcular redeemed_quotas:
    if @redemption.cotization_date.present? && @redemption.redeemed_liquid_value.present?
      quota_value = fund_investment.investment_fund.quota_value_on(@redemption.cotization_date)

      unless quota_value
        @redemption.errors.add(:base, "Sem cota disponível para esta data.")
        return render :new, status: :unprocessable_entity
      end

      calculated_quotas = BigDecimal(@redemption.redeemed_liquid_value.to_s) / quota_value

      # Para resgates totais, usa directamente as cotas disponíveis
      # evitando erro de arredondamento quando o valor de mercado
      # divide para ligeiramente mais cotas do que as detidas.
      @redemption.redeemed_quotas = if @redemption.redemption_type == "total"
                                      fund_investment.total_quotas_held
                                    else
                                      calculated_quotas
                                    end
    end

    if (@redemption.redeemed_quotas || 0) > (fund_investment.total_quotas_held || 0)
      @redemption.errors.add(:base, "Cotas insuficientes: disponível #{fund_investment.total_quotas_held}.")
      return render :new, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      @redemption.save!
      allocate_quotas_fifo(fund_investment, @redemption.redeemed_quotas)
      fund_investment.update_balances!(
        quotas_delta: -@redemption.redeemed_quotas,
        value_delta: -@redemption.redeemed_liquid_value
      )
      PortfolioAllocationCalculator.recalculate!(fund_investment.portfolio)
    end

    redirect_to fund_investment_path(fund_investment), notice: "Resgate criado com sucesso."

  rescue ActiveRecord::RecordInvalid => e
    @redemption = e.record
    render :new, status: :unprocessable_entity
  end

  # == edit
  #
  # @author Moisés Reis
  #
  # Loads the editing interface for an existing redemption.
  def edit
  end

  # == update
  #
  # @author Moisés Reis
  #
  # Updates the attributes of an existing redemption and redirects to its detail page.
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
  # Deletes a redemption, restores the consumed quotas to their original applications,
  # and recalculates portfolio balances.
  def destroy
    fund_investment = @redemption.fund_investment

    ActiveRecord::Base.transaction do
      revert_quotas_on_destroy(fund_investment)
      @redemption.destroy!
      PortfolioAllocationCalculator.recalculate!(fund_investment.portfolio)
    end

    respond_to do |format|
      format.html { redirect_to fund_investment_path(fund_investment), notice: "Resgate deletado com sucesso.", status: :see_other }
      format.json { render json: { status: "Success", message: "Resgate deletado com sucesso." }, status: :ok }
    end

  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.html { redirect_to redemption_path(@redemption), alert: "Falha ao deletar resgate." }
      format.json { render json: { status: "Error", errors: e.record.errors.full_messages }, status: :unprocessable_entity }
    end
  rescue CanCan::AccessDenied => e
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
  def load_redemption
    @redemption = Redemption.find(params[:id])
  end

  # Fetches all fund investments the user is allowed to access for form selection.
  def load_form_collections
    @fund_investments = FundInvestment
                          .accessible_to(current_user)
                          .includes(:investment_fund, :portfolio)
  end

  # Ensures the user has permission to manage the portfolio associated with the redemption.
  def authorize_redemption
    authorize! :manage, @redemption.fund_investment.portfolio
  end

  # Defines the strict list of parameters allowed to be modified through requests.
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
    applications = fund_investment.applications
                                  .includes(:redemption_allocations)
                                  .where("number_of_quotas > 0")
                                  .order(:cotization_date)

    applications.each do |app|
      break if remaining_quotas <= 0

      available = app.available_quotas
      next if available <= 0

      quotas_to_use = [available, remaining_quotas].min

      RedemptionAllocation.create!(
        redemption: @redemption,
        application: app,
        quotas_used: quotas_to_use
      )

      remaining_quotas -= quotas_to_use
    end
  end

  # == revert_quotas_on_destroy
  #
  # @author Moisés Reis
  #
  # Restores quotas to their source applications when a redemption is deleted
  # to maintain accurate historical and current balance records.
  def revert_quotas_on_destroy(fund_investment)
    allocations = @redemption.redemption_allocations.includes(:application)
    reverted_value = allocations.sum { |a| a.quotas_used * a.application.quota_value_at_application }

    allocations.each do |allocation|
      app = allocation.application
      app.update!(
        number_of_quotas: app.number_of_quotas + allocation.quotas_used,
        financial_value: app.financial_value + (allocation.quotas_used * app.quota_value_at_application)
      )
    end

    fund_investment.update_balances!(
      quotas_delta: allocations.sum(:quotas_used),
      value_delta: reverted_value
    )
  end

  # Sets the main title used for PDF exports.
  def pdf_export_title = "Resgates"

  # Sets the descriptive subtitle used for PDF exports.
  def pdf_export_subtitle = "Histórico de resgates realizados"

  # == pdf_export_columns
  #
  # @author Moisés Reis
  #
  # Defines the column structure, data formatting, and sizing for the PDF table.
  def pdf_export_columns
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
  def pdf_export_data
    fund_investment_ids = FundInvestment.accessible_to(current_user).select(:id)

    base_scope = Redemption
                   .where(fund_investment_id: fund_investment_ids)
                   .includes(fund_investment: [:portfolio, :investment_fund])

    @q = base_scope.ransack(params[:q])

    sort = REDEMPTIONS_ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "request_date"
    direction = REDEMPTIONS_ALLOWED_DIRECTIONS.include?(params[:direction]) ? params[:direction] : "desc"

    @q.result(distinct: true).order("#{sort} #{direction}")
  end

  # == pdf_export_metadata
  #
  # @author Moisés Reis
  #
  # Compiles high-level summary information, such as totals and user details, for the PDF header.
  def pdf_export_metadata
    h = ActionController::Base.helpers
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