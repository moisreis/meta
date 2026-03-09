# === fund_investments_controller.rb
#
# Description:: Manages the creation, listing, and detailed viewing of a user's
#               investments in specific funds.
#
# FIX: Added sort-column and direction whitelists to prevent SQL injection via
# unvalidated params[:sort] / params[:direction] reaching .order().
#
class FundInvestmentsController < ApplicationController

  include PdfExportable

  # FIX: Renamed to avoid boot-time constant collision.
  FUND_INVESTMENTS_ALLOWED_SORT_COLUMNS = %w[
    total_invested_value total_quotas_held percentage_allocation created_at
  ].freeze
  FUND_INVESTMENTS_ALLOWED_DIRECTIONS = %w[asc desc].freeze

  before_action :authenticate_user!

  before_action :load_fund_investment, only: %i[show update edit destroy]
  before_action :authorize_fund_investment, only: %i[show update edit destroy]
  before_action :load_form_dependencies, only: %i[new edit create]

  # =============================================================
  # Error handling
  # =============================================================

  rescue_from ActiveRecord::RecordNotFound do |e|
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: "Investimento não encontrado." }
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
    Rails.logger.error("[FundInvestmentsController] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    respond_to do |format|
      format.html { redirect_to portfolios_path, alert: "Ocorreu um erro inesperado." }
      format.json { render json: { error: "Internal server error" }, status: :internal_server_error }
    end
  end

  # =============================================================
  # Public Methods
  # =============================================================

  def index
    base_scope = accessible_fund_investments

    @q           = base_scope.ransack(params[:q])
    @total_items = FundInvestment.count

    filtered = @q.result(distinct: true)

    sort      = FUND_INVESTMENTS_ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "total_invested_value"
    direction = FUND_INVESTMENTS_ALLOWED_DIRECTIONS.include?(params[:direction]) ? params[:direction] : "desc"

    @fund_investments = filtered.order("#{sort} #{direction}").page(params[:page]).per(14)

    respond_to { |f| f.html }
  end

  def show; end

  def new
    @fund_investment = FundInvestment.new
  end

  def create
    @fund_investment = FundInvestment.new(fund_investment_params)

    if @fund_investment.save
      redirect_to @fund_investment.portfolio, notice: "Investimento criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update; end

  def destroy
    portfolio = @fund_investment.portfolio
    @fund_investment.destroy
    redirect_to portfolio, notice: "Investimento removido com sucesso."
  end

  def edit; end

  def delete; end

  private

  def load_fund_investment
    @fund_investment = FundInvestment.find(params[:id])
  end

  def authorize_fund_investment
    authorize! :read,   @fund_investment if action_name == "show"
    authorize! :manage, @fund_investment if %w[update destroy edit].include?(action_name)
  end

  def fund_investment_params
    params.require(:fund_investment).permit(
      :portfolio_id,
      :investment_fund_id,
      :total_invested_value,
      :total_quotas_held,
      :percentage_allocation
    )
  end

  def accessible_fund_investments
    FundInvestment.accessible_to(current_user).includes(:portfolio, :investment_fund)
  end

  def market_value_on
    fund_investment = FundInvestment.find(params[:id])
    date            = Date.parse(params[:date])
    quota           = fund_investment.investment_fund.quota_value_on(date)
    quotas          = fund_investment.applications.sum(:number_of_quotas) -
                      fund_investment.redemptions.sum(:redeemed_quotas)
    value           = quota ? (quotas * quota).round(2) : nil

    render json: { value: value, quota: quota, date: date }
  end

  def load_form_dependencies
    @investment_funds = InvestmentFund.all
    @portfolios       = accessible_portfolios
  end

  def accessible_portfolios
    current_user.portfolios
  end

  def pdf_export_title    = "Investimentos em Fundos"
  def pdf_export_subtitle = "Relatório de investimentos ativos"

  def pdf_export_columns
    h = ActionController::Base.helpers

    [
      { header: "Fundo",   key: ->(fi) { fi.investment_fund.fund_name } },
      { header: "CNPJ",    key: ->(fi) { fi.investment_fund.cnpj } },
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

  def pdf_export_data
    FundInvestment.joins(:portfolio)
                  .where(portfolios: { user_id: current_user.id })
                  .includes(:investment_fund, :portfolio)
  end

  def pdf_export_metadata
    h = ActionController::Base.helpers

    {
      "Usuário"        => current_user.full_name,
      "Total investido" => h.number_to_currency(pdf_export_data.sum(:total_invested_value))
    }
  end
end
