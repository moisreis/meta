# === performance_histories_controller.rb
#
# Description:: Manages PerformanceHistory records — listing, viewing, creating,
#               editing, and deleting historical return data for fund investments.
#
# FIX: Added sort-column and direction whitelists to prevent SQL injection via
# unvalidated params[:sort] / params[:direction] reaching .order().
#
class PerformanceHistoriesController < ApplicationController

  # FIX: Renamed constants to avoid boot-time collision.
  PERF_HISTORIES_ALLOWED_SORT_COLUMNS = %w[period monthly_return yearly_return last_12_months_return earnings initial_balance].freeze
  PERF_HISTORIES_ALLOWED_DIRECTIONS   = %w[asc desc].freeze

  before_action :authenticate_user!
  before_action :load_performance_history,    only: %i[show edit update destroy]
  before_action :authorize_performance_history, only: %i[show update destroy]

  # =============================================================
  # Error handling
  # =============================================================

  rescue_from ActiveRecord::RecordNotFound do |e|
    respond_to do |format|
      format.html { redirect_to performance_histories_path, alert: "Registro não encontrado." }
      format.json { render json: { error: e.message }, status: :not_found }
    end
  end

  rescue_from CanCan::AccessDenied do |e|
    respond_to do |format|
      format.html { redirect_to performance_histories_path, alert: e.message }
      format.json { render json: { error: e.message }, status: :forbidden }
    end
  end

  rescue_from StandardError do |e|
    Rails.logger.error("[PerformanceHistoriesController] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    respond_to do |format|
      format.html { redirect_to performance_histories_path, alert: "Ocorreu um erro inesperado." }
      format.json { render json: { error: "Internal server error" }, status: :internal_server_error }
    end
  end

  # =============================================================
  # Public Methods
  # =============================================================

  def index
    base_scope = PerformanceHistory.all
                                   .includes(:portfolio, fund_investment: :investment_fund)
                                   .order(period: :desc)

    @q           = base_scope.ransack(params[:q])
    @total_items = PerformanceHistory.count

    filtered = @q.result(distinct: true)

    sort      = PERF_HISTORIES_ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "period"
    direction = PERF_HISTORIES_ALLOWED_DIRECTIONS.include?(params[:direction]) ? params[:direction] : "desc"

    @performance_histories = filtered.order("#{sort} #{direction}").page(params[:page]).per(14)

    respond_to do |format|
      format.html
      format.json {
        render json: {
          status: "Success",
          data: PerformanceHistorySerializer.new(@performance_histories).serializable_hash
        }
      }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json {
        render json: {
          status: "Success",
          data: PerformanceHistorySerializer.new(@performance_history).serializable_hash[:data][:attributes]
        }
      }
    end
  end

  def new
    @performance_history = PerformanceHistory.new

    @performance_history.portfolio_id      = params[:portfolio_id]      if params[:portfolio_id].present?
    @performance_history.fund_investment_id = params[:fund_investment_id] if params[:fund_investment_id].present?

    authorize! :create, PerformanceHistory
  rescue CanCan::AccessDenied => e
    redirect_to performance_histories_path, alert: e.message
  end

  def edit; end

  def create
    @performance_history = PerformanceHistory.new(performance_history_params)
    authorize! :create, PerformanceHistory

    if @performance_history.save
      respond_to do |format|
        format.html { redirect_to performance_history_path(@performance_history), notice: "Histórico de performance criado com sucesso" }
        format.json {
          render json: {
            status: "Success",
            data: PerformanceHistorySerializer.new(@performance_history).serializable_hash[:data][:attributes]
          }, status: :created
        }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { status: "Error", errors: @performance_history.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  rescue CanCan::AccessDenied => e
    respond_to do |format|
      format.html { redirect_to performance_histories_path, alert: e.message }
      format.json { render json: { status: "Error", message: e.message }, status: :forbidden }
    end
  end

  def update
    if @performance_history.update(performance_history_params)
      respond_to do |format|
        format.html { redirect_to performance_history_path(@performance_history), notice: "Histórico de performance atualizado com sucesso" }
        format.json {
          render json: {
            status: "Success",
            data: PerformanceHistorySerializer.new(@performance_history).serializable_hash[:data][:attributes]
          }
        }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { status: "Error", errors: @performance_history.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @performance_history.destroy!

    respond_to do |format|
      format.html { redirect_to performance_histories_path, notice: "Histórico de performance deletado com sucesso.", status: :see_other }
      format.json { render json: { status: "Success", message: "Histórico de performance deletado com sucesso." }, status: :ok }
    end

  rescue ActiveRecord::RecordNotDestroyed => e
    respond_to do |format|
      format.html { redirect_to performance_history_path(@performance_history), alert: "Houve um problema ao deletar o histórico de performance" }
      format.json { render json: { status: "Error", message: "Failed to delete", errors: e.record.errors.full_messages }, status: :unprocessable_entity }
    end
  end

  private

  def load_performance_history
    @performance_history = PerformanceHistory.includes(:portfolio, fund_investment: :investment_fund)
                                             .find(params[:id])
  end

  def authorize_performance_history
    authorize! :read,   @performance_history if action_name == "show"
    authorize! :manage, @performance_history if %w[update destroy].include?(action_name)
  end

  def performance_history_params
    params.require(:performance_history).permit(
      :portfolio_id,
      :fund_investment_id,
      :period,
      :monthly_return,
      :yearly_return,
      :last_12_months_return,
      :earnings
    )
  end
end
