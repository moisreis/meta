# === performance_histories_controller.rb
#
# Description:: Manages PerformanceHistory records — listing, viewing, creating,
#               editing, and deleting historical return data for fund investments.
#
# Usage:: - *What* - A management interface for tracking financial performance
#           history over time for various fund investments.
#         - *How* - It processes requests to interact with historical data,
#           utilizing filtering, sorting, and authorization logic to ensure
#           users only access appropriate information.
#         - *Why* - Historical performance data is crucial for analyzing investment
#           success, calculating trends, and providing transparency to users.
#
# Attributes:: - *@performance_histories* [Collection] - A list of performance records.
#              - *@performance_history* [Object] - A single performance record being processed.
#
class PerformanceHistoriesController < ApplicationController

  # =============================================================
  #                        CONFIGURATION
  # =============================================================

  # Lists permitted columns for sorting to prevent malicious SQL queries.
  PERF_HISTORIES_ALLOWED_SORT_COLUMNS = %w[period monthly_return yearly_return last_12_months_return earnings initial_balance].freeze

  # Lists permitted directions for sorting to ensure query safety.
  PERF_HISTORIES_ALLOWED_DIRECTIONS = %w[asc desc].freeze

  # Confirms that a user is logged into the system before access.
  before_action :authenticate_user!

  # Loads the performance history record for specific operations before they occur.
  before_action :load_performance_history, only: %i[show edit update destroy]

  # Ensures only authorized users can view or modify specific performance records.
  before_action :authorize_performance_history, only: %i[show update destroy]

  # =============================================================
  #                      ERROR HANDLING
  # =============================================================

  # Handles missing records by redirecting the user back to the list.
  rescue_from ActiveRecord::RecordNotFound do |e|
    respond_to do |format|
      format.html { redirect_to performance_histories_path, alert: "Registro não encontrado." }
      format.json { render json: { error: e.message }, status: :not_found }
    end
  end

  # Handles authorization failures by warning the user of restricted access.
  rescue_from CanCan::AccessDenied do |e|
    respond_to do |format|
      format.html { redirect_to performance_histories_path, alert: e.message }
      format.json { render json: { error: e.message }, status: :forbidden }
    end
  end

  # Captures unexpected system errors and logs details for debugging.
  rescue_from StandardError do |e|
    Rails.logger.error("[PerformanceHistoriesController] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    respond_to do |format|
      format.html { redirect_to performance_histories_path, alert: "Ocorreu um erro inesperado." }
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
  # Displays a paginated, searchable list of performance history records.
  def index
    base_scope = PerformanceHistory.all
                                   .includes(:portfolio, fund_investment: :investment_fund)
                                   .order(period: :desc)

    @q = base_scope.ransack(params[:q])
    @total_items = PerformanceHistory.count

    filtered = @q.result(distinct: true)

    # Validates sort parameters to prevent SQL injection attempts.
    sort = PERF_HISTORIES_ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "period"
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

  # == show
  #
  # @author Moisés Reis
  #
  # Displays the details of a single performance history record.
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

  # == new
  #
  # @author Moisés Reis
  #
  # Prepares a blank performance history record for the entry form.
  def new
    @performance_history = PerformanceHistory.new

    @performance_history.portfolio_id = params[:portfolio_id] if params[:portfolio_id].present?
    @performance_history.fund_investment_id = params[:fund_investment_id] if params[:fund_investment_id].present?

    authorize! :create, PerformanceHistory
  rescue CanCan::AccessDenied => e
    redirect_to performance_histories_path, alert: e.message
  end

  # == edit
  #
  # @author Moisés Reis
  #
  # Placeholder for loading the editing interface.
  def edit
  end

  # == create
  #
  # @author Moisés Reis
  #
  # Saves a new performance history entry and returns the status.
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

  # == update
  #
  # @author Moisés Reis
  #
  # Saves changes to an existing performance history record.
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

  # == destroy
  #
  # @author Moisés Reis
  #
  # Permanently removes a performance history record from the system.
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

  # =============================================================
  #                       HELPER UTILITIES
  # =============================================================

  private

  # Retrieves the specific performance history record from the database.
  def load_performance_history
    @performance_history = PerformanceHistory.includes(:portfolio, fund_investment: :investment_fund)
                                             .find(params[:id])
  end

  # Checks user permissions for the current performance record operation.
  def authorize_performance_history
    authorize! :read, @performance_history if action_name == "show"
    authorize! :manage, @performance_history if %w[update destroy].include?(action_name)
  end

  # Filters parameters allowed for saving performance history data.
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