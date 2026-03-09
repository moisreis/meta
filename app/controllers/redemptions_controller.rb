# =============================================================
# Configuration & Dependencies
# =============================================================

# FIX: Renamed to avoid constant redefinition collisions at boot.
REDEMPTIONS_ALLOWED_SORT_COLUMNS = %w[request_date cotization_date liquidation_date redeemed_liquid_value redeemed_quotas].freeze
REDEMPTIONS_ALLOWED_DIRECTIONS   = %w[asc desc].freeze

# === redemptions_controller.rb
#
# Description:: Manages the lifecycle of investment redemptions within the system.
#
class RedemptionsController < ApplicationController

  include PdfExportable

  before_action :authenticate_user!
  before_action :load_form_collections, only: %i[new create edit update]
  before_action :load_redemption,       only: %i[show edit update destroy]
  before_action :authorize_redemption,  only: %i[show update destroy]

  # =============================================================
  # Error handling
  # =============================================================

  rescue_from ActiveRecord::RecordNotFound do |e|
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: "Registro não encontrado." }
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
    Rails.logger.error("[RedemptionsController] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: "Ocorreu um erro inesperado." }
      format.json { render json: { error: "Internal server error" }, status: :internal_server_error }
    end
  end

  # =============================================================
  # Public Methods
  # =============================================================

  def index
    fund_investment_ids = FundInvestment.accessible_to(current_user).select(:id)

    base_scope = Redemption
                   .where(fund_investment_id: fund_investment_ids)
                   .includes(fund_investment: [:portfolio, :investment_fund])

    @q = base_scope.ransack(params[:q])
    filtered = @q.result(distinct: true)

    @total_items = filtered.count

    sort      = REDEMPTIONS_ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "request_date"
    direction = REDEMPTIONS_ALLOWED_DIRECTIONS.include?(params[:direction]) ? params[:direction] : "desc"

    @redemptions = filtered.order("#{sort} #{direction}").page(params[:page]).per(14)

    respond_to { |f| f.html }
  end

  def show; end

  def new
    @redemption = Redemption.new
  end

  def create
    @redemption     = Redemption.new(redemption_params)
    fund_investment = @redemption.fund_investment

    unless fund_investment
      @redemption.errors.add(:fund_investment_id, "não encontrado")
      return render :new, status: :unprocessable_entity
    end

    authorize! :manage, fund_investment.portfolio

    if @redemption.cotization_date.present? && @redemption.redeemed_liquid_value.present?
      quota_value = fund_investment.investment_fund.quota_value_on(@redemption.cotization_date)

      unless quota_value
        @redemption.errors.add(:base, "Sem cota disponível para esta data.")
        return render :new, status: :unprocessable_entity
      end

      @redemption.redeemed_quotas = BigDecimal(@redemption.redeemed_liquid_value.to_s) / quota_value
    end

    # Early quota check with a friendly message before hitting model validation.
    if (@redemption.redeemed_quotas || 0) > (fund_investment.total_quotas_held || 0)
      @redemption.errors.add(:base, "Cotas insuficientes: disponível #{fund_investment.total_quotas_held}.")
      return render :new, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      @redemption.save!
      allocate_quotas_fifo(fund_investment, @redemption.redeemed_quotas)
      fund_investment.update_balances!(
        quotas_delta: -@redemption.redeemed_quotas,
        value_delta:  -@redemption.redeemed_liquid_value
      )
      PortfolioAllocationCalculator.recalculate!(fund_investment.portfolio)
    end

    redirect_to fund_investment_path(fund_investment), notice: "Resgate criado com sucesso."

  rescue ActiveRecord::RecordInvalid => e
    @redemption = e.record
    render :new, status: :unprocessable_entity
  end

  def edit; end

  def update
    if @redemption.update(redemption_params)
      redirect_to redemption_path(@redemption), notice: "Resgate atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    fund_investment = @redemption.fund_investment

    ActiveRecord::Base.transaction do
      revert_quotas_on_destroy(fund_investment)
      @redemption.destroy!
      PortfolioAllocationCalculator.recalculate!(fund_investment.portfolio)
    end

    render json: { status: "Success", message: "Resgate deletado com sucesso." }, status: :ok

  rescue ActiveRecord::RecordInvalid => e
    render json: { status: "Error", message: "Falha ao deletar resgate.", errors: e.record.errors.full_messages }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound => e
    render json: { status: "Error", message: "Resgate não encontrado: #{e.message}" }, status: :not_found
  rescue CanCan::AccessDenied => e
    render json: { status: "Error", message: e.message }, status: :forbidden
  end

  # =============================================================
  # Private Methods
  # =============================================================

  private

  def load_redemption
    @redemption = Redemption.find(params[:id])
  end

  # FIX: Previously filtered only by portfolios.user_id = current_user.id, which
  # excluded shared portfolios where the user has manage permission.
  # Updated to use FundInvestment.accessible_to so that users with crud permission
  # on a shared portfolio can also create redemptions against it.
  def load_form_collections
    @fund_investments = FundInvestment
                          .accessible_to(current_user)
                          .includes(:investment_fund, :portfolio)
  end

  def authorize_redemption
    authorize! :manage, @redemption.fund_investment.portfolio
  end

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
  # Distributes the redeemed amount across existing applications using FIFO.
  # Uses available_quotas (which accounts for prior redemption allocations) rather
  # than the raw number_of_quotas field to avoid over-allocating a partially
  # redeemed application.
  def allocate_quotas_fifo(fund_investment, remaining_quotas)
    applications = fund_investment.applications
                                  .includes(:redemption_allocations)
                                  .where("number_of_quotas > 0")
                                  .order(:cotization_date)

    applications.each do |app|
      break if remaining_quotas <= 0

      available     = app.available_quotas
      next if available <= 0

      quotas_to_use = [available, remaining_quotas].min

      RedemptionAllocation.create!(
        redemption:  @redemption,
        application: app,
        quotas_used: quotas_to_use
      )

      remaining_quotas -= quotas_to_use
    end
  end

  def revert_quotas_on_destroy(fund_investment)
    allocations    = @redemption.redemption_allocations.includes(:application)
    reverted_value = allocations.sum { |a| a.quotas_used * a.application.quota_value_at_application }

    allocations.each do |allocation|
      app = allocation.application
      app.update_columns(
        number_of_quotas: app.number_of_quotas + allocation.quotas_used,
        updated_at:       Time.current
      )
    end

    fund_investment.update_balances!(
      quotas_delta: allocations.sum(:quotas_used),
      value_delta:  reverted_value
    )
  end

  def pdf_export_title    = "Resgates"
  def pdf_export_subtitle = "Histórico de resgates realizados"

  def pdf_export_columns
    h = ActionController::Base.helpers

    [
      { header: "Data Solicitação", key: ->(r) { r.request_date   ? I18n.l(r.request_date,   format: :short) : "N/A" }, width: 85 },
      { header: "Data Cotização",   key: ->(r) { r.cotization_date ? I18n.l(r.cotization_date, format: :short) : "N/A" }, width: 85 },
      { header: "Fundo",     key: ->(r) { r.fund_investment.investment_fund.fund_name }, width: 150 },
      { header: "Carteira",  key: ->(r) { r.fund_investment.portfolio.name },             width: 100 },
      { header: "Tipo",      key: ->(r) { r.redemption_type&.capitalize || "N/A" },       width: 60  },
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

  def pdf_export_data
    fund_investment_ids = FundInvestment.accessible_to(current_user).select(:id)

    base_scope = Redemption
                   .where(fund_investment_id: fund_investment_ids)
                   .includes(fund_investment: [:portfolio, :investment_fund])

    @q = base_scope.ransack(params[:q])

    sort      = REDEMPTIONS_ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "request_date"
    direction = REDEMPTIONS_ALLOWED_DIRECTIONS.include?(params[:direction]) ? params[:direction] : "desc"

    @q.result(distinct: true).order("#{sort} #{direction}")
  end

  def pdf_export_metadata
    h    = ActionController::Base.helpers
    data = pdf_export_data

    {
      "Usuário"               => current_user.full_name,
      "E-mail"                => current_user.email,
      "Total de resgates"     => data.size.to_s,
      "Valor total resgatado" => h.number_to_currency(data.sum(:redeemed_liquid_value), unit: "R$ ", separator: ",", delimiter: "."),
      "Cotas totais resgatadas" => h.number_with_precision(data.sum(:redeemed_quotas), precision: 2, separator: ",", delimiter: ".")
    }
  end
end
