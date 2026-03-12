# === investment_funds_controller.rb
#
# Description:: Manages all available InvestmentFund records in the system.
#
# FIX: Added sort-column and direction whitelists to prevent SQL injection via
# unvalidated params[:sort] / params[:direction] reaching .order().
#
class InvestmentFundsController < ApplicationController

  # FIX: Renamed to avoid boot-time constant collision.
  INVESTMENT_FUNDS_ALLOWED_SORT_COLUMNS = %w[cnpj fund_name administrator_name created_at].freeze
  INVESTMENT_FUNDS_ALLOWED_DIRECTIONS   = %w[asc desc].freeze

  before_action :authenticate_user!
  before_action :load_investment_fund,    only: %i[show edit update destroy]
  before_action :authorize_investment_fund, only: %i[show update destroy]

  # =============================================================
  # Error handling
  # =============================================================

  rescue_from ActiveRecord::RecordNotFound do |e|
    respond_to do |format|
      format.html { redirect_to investment_funds_path, alert: "Fundo não encontrado." }
      format.json { render json: { error: e.message }, status: :not_found }
    end
  end

  rescue_from CanCan::AccessDenied do |e|
    respond_to do |format|
      format.html { redirect_to investment_funds_path, alert: e.message }
      format.json { render json: { error: e.message }, status: :forbidden }
    end
  end

  rescue_from StandardError do |e|
    Rails.logger.error("[InvestmentFundsController] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    respond_to do |format|
      format.html { redirect_to investment_funds_path, alert: "Ocorreu um erro inesperado." }
      format.json { render json: { error: "Internal server error" }, status: :internal_server_error }
    end
  end

  # =============================================================
  # Public Methods
  # =============================================================

  def index
    if params.dig(:q, :cnpj_cont).present?
      digits = params[:q][:cnpj_cont].gsub(/\D/, "")
      params[:q][:cnpj_cont] = digits.sub(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '\1.\2.\3/\4-\5')
    end

    base_scope = InvestmentFund.all.order(created_at: :desc)

    @q           = base_scope.ransack(params[:q])
    @total_items = InvestmentFund.count

    filtered = @q.result(distinct: true)

    sort      = INVESTMENT_FUNDS_ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "cnpj"
    direction = INVESTMENT_FUNDS_ALLOWED_DIRECTIONS.include?(params[:direction]) ? params[:direction] : "asc"

    @models            = filtered.order("#{sort} #{direction}").page(params[:page]).per(14)
    @investment_funds  = @models

    respond_to { |f| f.html }
  end

  def show; end

  def new
    @investment_fund = InvestmentFund.new
  end

  def edit; end

  def create
    @investment_fund = InvestmentFund.new(investment_fund_params)
    authorize! :create, InvestmentFund

    if @investment_fund.save
      redirect_to @investment_fund, notice: "O credenciamento de fundo de investimento foi criado com sucesso"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @investment_fund.update(investment_fund_params)
      redirect_to @investment_fund, notice: "O credenciamento de fundo de investimento foi atualizado com sucesso"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @investment_fund.destroy
    redirect_to investment_funds_path, notice: "O credenciamento de fundo de investimento foi deletado com sucesso"
  end

  def lookup
    result = CvmFundLookupService.call(params[:cnpj].to_s)
    render json: result
  end

  private

  def load_investment_fund
    @investment_fund = InvestmentFund.find(params[:id])
  end

  def authorize_investment_fund
    authorize! :read,   @investment_fund if action_name == "show"
    authorize! :manage, @investment_fund if %w[update destroy].include?(action_name)
  end

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
