# =============================================================
# Configuration & Dependencies
# =============================================================

# FIX: Renamed constants to avoid redefinition collision with identical names in
# redemptions_controller.rb and portfolios_controller.rb at boot time.
APPLICATIONS_ALLOWED_SORT_COLUMNS = %w[request_date cotization_date liquidation_date financial_value].freeze
APPLICATIONS_ALLOWED_DIRECTIONS   = %w[asc desc].freeze

# === applications_controller.rb
#
# Description:: Manages the lifecycle of investment applications within the system.
#
class ApplicationsController < ApplicationController

  before_action :authenticate_user!
  before_action :load_application,    only: %i[show edit update destroy]
  before_action :authorize_application, only: %i[show edit update destroy]
  before_action :load_form_dependencies, only: %i[new edit create]

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
    Rails.logger.error("[ApplicationsController] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
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

    base_scope = Application
                   .where(fund_investment_id: fund_investment_ids)
                   .includes(fund_investment: [:portfolio, :investment_fund])

    @q = base_scope.ransack(params[:q])
    filtered = @q.result(distinct: true)

    @total_items = filtered.count

    sort      = APPLICATIONS_ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "request_date"
    direction = APPLICATIONS_ALLOWED_DIRECTIONS.include?(params[:direction]) ? params[:direction] : "desc"

    @applications = filtered.order("#{sort} #{direction}").page(params[:page]).per(14)

    respond_to { |f| f.html }
  end

  def show
    prepare_application_metrics
    respond_to { |f| f.html }
  end

  def new
    @application = Application.new
  end

  def edit; end

  def create
    portfolio = Portfolio.find(application_params[:portfolio_id])
    fund      = InvestmentFund.find(application_params[:investment_fund_id])

    authorize! :manage, portfolio

    fund_investment = FundInvestment.find_or_create_by!(
      investment_fund: fund,
      portfolio:       portfolio
    ) do |fi|
      fi.skip_allocation_validation = true
      fi.percentage_allocation  = 0
      fi.total_invested_value   = 0
      fi.total_quotas_held      = 0
    end

    @application = Application.new(
      application_params.except(:portfolio_id, :investment_fund_id)
                        .merge(fund_investment: fund_investment)
    )

    if @application.cotization_date.present? && @application.financial_value.present?
      quota_value = fund.quota_value_on(@application.cotization_date)

      unless quota_value
        @application.errors.add(:cotization_date, "Não há cota disponível para esta data")
        return render :new, status: :unprocessable_entity
      end

      @application.quota_value_at_application = quota_value
      @application.number_of_quotas = BigDecimal(@application.financial_value.to_s) / quota_value
    end

    ActiveRecord::Base.transaction do
      @application.save!
      fund_investment.update_balances!(
        quotas_delta: @application.number_of_quotas || 0,
        value_delta:  @application.financial_value  || 0
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

  def update
    redirect_to application_path(@application), status: :method_not_allowed
  end

  def destroy
    fund_investment = @application.fund_investment

    ActiveRecord::Base.transaction do
      fund_investment.update_balances!(
        quotas_delta: -(@application.number_of_quotas || 0),
        value_delta:  -(@application.financial_value  || 0)
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
  # Private Methods
  # =============================================================

  private

  def load_application
    @application = Application.find(params[:id])
  end

  def load_form_dependencies
    @fund_investments = FundInvestment
                          .accessible_to(current_user)
                          .includes(:portfolio, :investment_fund)
  end

  def authorize_application
    authorize! :manage, @application.fund_investment.portfolio
  end

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

  def parsed_date_params
    date_fields = %i[request_date cotization_date liquidation_date]
    raw         = params.require(:application)

    date_fields.each_with_object({}) do |field, hash|
      raw_value = raw[field].presence
      next unless raw_value

      parsed = parse_br_date(raw_value)
      hash[field] = parsed if parsed
    end
  end

  def parse_br_date(value)
    return value unless value.match?(%r{\A\d{2}/\d{2}/\d{4}\z})

    day, month, year = value.split("/")
    Date.new(year.to_i, month.to_i, day.to_i).iso8601
  rescue ArgumentError
    nil
  end

  def prepare_application_metrics
    allocated_quotas = @application.redemption_allocations.sum(:quotas_used) || 0

    @allocation_percentage =
      if @application.number_of_quotas.to_f.positive?
        (allocated_quotas.to_f / @application.number_of_quotas.to_f) * 100
      else
        0
      end

    @processing_days =
      if @application.request_date && @application.liquidation_date
        (@application.liquidation_date - @application.request_date).to_i
      end

    @calculated_quota_value = @application.calculated_quota_value
    @stored_quota_value     = @application.quota_value_at_application

    @is_quota_consistent =
      @calculated_quota_value &&
      @stored_quota_value &&
      (@calculated_quota_value - @stored_quota_value).abs <= 0.01

    @cotization_valid =
      !@application.cotization_date ||
      !@application.request_date ||
      @application.cotization_date >= @application.request_date

    @liquidation_valid =
      !@application.liquidation_date ||
      !@application.cotization_date ||
      @application.liquidation_date >= @application.cotization_date

    @positive_values =
      @application.financial_value.to_f.positive? &&
      (@application.number_of_quotas.nil? || @application.number_of_quotas.to_f.positive?)

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
