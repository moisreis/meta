# === performance_histories_controller
#
# @author Moisés Reis
# @added 12/04/2025
# @package *Meta*
# @description This controller manages all available **PerformanceHistory** records in the system.
#              It handles listing, viewing, creation, editing, and deletion of historical
#              return data for fund investments within portfolios.
# @category *Controller*
#
# Usage:: - *[What]* This code block controls the master list of all performance history records
#           that track returns over time for investments across all portfolios.
#         - *[How]* It uses authorization checks via **CanCan** to manage who can create
#           or modify records, and it handles searching, filtering, and sorting of the history list.
#         - *[Why]* It provides a centralized and secure mechanism for managing the performance
#           tracking and analytics data used throughout the application.
#
# Attributes:: - *@performance_history* @object - The specific history record being handled (show, update, destroy).
#              - *@performance_histories* @collection - The filtered and paginated list of records for the index view.
#
class PerformanceHistoriesController < ApplicationController

  # Explanation:: This command confirms that a user is successfully logged into
  #               the system before allowing access to any actions within this controller.
  before_action :authenticate_user!

  # Explanation:: This runs before viewing, editing, updating, or destroying a record. It finds
  #               the specific **PerformanceHistory** from the database using the ID provided
  #               in the web address.
  before_action :load_performance_history, only: [
    :show,
    :edit,
    :update,
    :destroy
  ]

  # Explanation:: This runs immediately after loading the record. It checks the user's
  #               permissions via **CanCan** to ensure they are authorized to perform
  #               the requested action (read, update, or destroy) on this specific record.
  before_action :authorize_performance_history, only: [
    :show,
    :update,
    :destroy
  ]

  # == index
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action retrieves and displays a list of all performance history records.
  #        It applies search, filtering, and sorting before displaying the results to the user.
  #
  # Attributes:: - *@q* @Ransack::Search - holds the search object for the collection.
  #             - *@performance_histories* @ActiveRecord::Relation - contains the final paginated list.
  #
  def index

    # Explanation:: This defines the initial set of records by getting all **PerformanceHistory**
    #               entries and ordering them by period date, with the most recent appearing first.
    base_scope = PerformanceHistory.all
                                   .includes(:portfolio, fund_investment: :investment_fund)
                                   .order(period: :desc)

    # Explanation:: This initializes the search object using the **Ransack** gem,
    #               applying any search criteria passed by the user in the web address.
    @q = base_scope.ransack(params[:q])

    # Explanation:: This executes the search query defined by **Ransack**, returning a
    #               unique list of performance history records that match the search criteria.
    filtered = @q.result(distinct: true)

    # Explanation:: This checks the web address for a specific column to sort by, defaulting
    #               to sorting by the `period` date if no sort column is specified.
    sort = params[:sort].presence || "period"

    # Explanation:: This checks the web address for a specific sort direction, defaulting
    #               to descending order (most recent first) if none is specified.
    direction = params[:direction].presence || "desc"

    # Explanation:: This applies the determined sort column and direction to the
    #               filtered list of performance history records.
    sorted = filtered.order("#{sort} #{direction}")

    # Explanation:: This prepares the final data for the page, dividing the complete
    #               list into pages of 20 items to improve performance and readability.
    @performance_histories = sorted.page(params[:page]).per(20)

    respond_to do |format|
      format.html
      format.json {
        render json: {
          status: 'Success',
          data: PerformanceHistorySerializer.new(@performance_histories).serializable_hash
        }
      }
    end
  end

  # == show
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action prepares the specific performance history record that was loaded earlier.
  #        It makes the data available for the view to display all its details to the user.
  #
  # Attributes:: - *@performance_history* @PerformanceHistory - The single record found by the `load_performance_history` filter.
  #
  def show
    respond_to do |format|
      format.html
      format.json {
        render json: {
          status: 'Success',
          data: PerformanceHistorySerializer.new(@performance_history).serializable_hash[:data][:attributes]
        }
      }
    end
  end

  # == new
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action creates a new, blank **PerformanceHistory** object.
  #        This empty object is used by the form to gather input from the user for creation.
  #
  # Attributes:: - *@performance_history* @PerformanceHistory - A new, unsaved record instance.
  #
  def new
    @performance_history = PerformanceHistory.new

    # Explanation:: This pre-fills the portfolio_id if it's passed in the URL parameters,
    #               making it easier to create records from a portfolio's show page.
    if params[:portfolio_id].present?
      @performance_history.portfolio_id = params[:portfolio_id]
    end

    # Explanation:: This pre-fills the fund_investment_id if it's passed in the URL parameters,
    #               making it easier to create records from a fund investment context.
    if params[:fund_investment_id].present?
      @performance_history.fund_investment_id = params[:fund_investment_id]
    end

    # Explanation:: This checks if the current user has permission to create performance history records.
    #               If not, they are redirected to the index page with an error message.
    authorize! :create, PerformanceHistory
  rescue CanCan::AccessDenied => e
    redirect_to performance_histories_path, alert: e.message
  end

  # == edit
  #
  # @author Moisés Reis
  # @category *Edit*
  #
  # Edit:: This action prepares the view to display the existing record's
  #        data, allowing the user to make changes to the performance metrics.
  #
  # Attributes:: - *@performance_history* @PerformanceHistory - The existing record loaded by the `before_action` filter.
  #
  def edit
  end

  # == create
  #
  # @author Moisés Reis
  # @category *Create*
  #
  # Create:: This action attempts to save a new performance history record to the
  #          database. It first checks for creation permissions and handles
  #          both successful saves and validation errors.
  #
  # Attributes:: - *@performance_history* @PerformanceHistory - The new record.
  #
  def create
    @performance_history = PerformanceHistory.new(performance_history_params)

    # Explanation:: This uses **CanCan** to verify that the current user has permission
    #               to create a new **PerformanceHistory** record in the system.
    authorize! :create, PerformanceHistory

    # Explanation:: This attempts to save the new record to the database.
    #               If successful, it redirects to the show page with a success message.
    if @performance_history.save
      respond_to do |format|
        format.html {
          redirect_to performance_history_path(@performance_history),
                      notice: 'Performance history was successfully created.'
        }
        format.json {
          render json: {
            status: 'Success',
            data: PerformanceHistorySerializer.new(@performance_history).serializable_hash[:data][:attributes]
          }, status: :created
        }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json {
          render json: {
            status: 'Error',
            errors: @performance_history.errors.full_messages
          }, status: :unprocessable_entity
        }
      end
    end

  rescue CanCan::AccessDenied => e
    respond_to do |format|
      format.html { redirect_to performance_histories_path, alert: e.message }
      format.json {
        render json: {
          status: 'Error',
          message: e.message
        }, status: :forbidden
      }
    end
  end

  # == update
  #
  # @author Moisés Reis
  # @category *Update*
  #
  # Update:: This action attempts to modify an existing performance history record
  #          with new data. It handles both successful updates and validation errors.
  #
  # Attributes:: - *@performance_history* @PerformanceHistory - The record to be updated.
  #
  def update

    # Explanation:: This attempts to update the record with the sanitized parameters.
    #               If successful, it redirects to the show page with a success message.
    if @performance_history.update(performance_history_params)
      respond_to do |format|
        format.html {
          redirect_to performance_history_path(@performance_history),
                      notice: 'Performance history was successfully updated.'
        }
        format.json {
          render json: {
            status: 'Success',
            data: PerformanceHistorySerializer.new(@performance_history).serializable_hash[:data][:attributes]
          }
        }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json {
          render json: {
            status: 'Error',
            errors: @performance_history.errors.full_messages
          }, status: :unprocessable_entity
        }
      end
    end
  end

  # == destroy
  #
  # @author Moisés Reis
  # @category *Delete*
  #
  # Delete:: This action deletes the performance history record from the database.
  #          It handles successful deletion and any errors that might occur.
  #
  # Attributes:: - *@performance_history* @PerformanceHistory - The record to be destroyed.
  #
  def destroy

    # Explanation:: This attempts to destroy the record.
    #               If successful, it redirects to the index with a success message.
    @performance_history.destroy!

    respond_to do |format|
      format.html {
        redirect_to performance_histories_path,
                    notice: 'Performance history was successfully deleted.',
                    status: :see_other
      }
      format.json {
        render json: {
          status: 'Success',
          message: 'Performance history deleted successfully'
        }, status: :ok
      }
    end

  rescue ActiveRecord::RecordNotDestroyed => e
    respond_to do |format|
      format.html {
        redirect_to performance_history_path(@performance_history),
                    alert: 'Failed to delete performance history'
      }
      format.json {
        render json: {
          status: 'Error',
          message: 'Failed to delete performance history',
          errors: e.record.errors.full_messages
        }, status: :unprocessable_entity
      }
    end

  rescue ActiveRecord::RecordNotFound => e
    respond_to do |format|
      format.html { redirect_to performance_histories_path, alert: 'Performance history not found' }
      format.json {
        render json: {
          status: 'Error',
          message: "Performance history not found: #{e.message}"
        }, status: :not_found
      }
    end

  rescue CanCan::AccessDenied => e
    respond_to do |format|
      format.html { redirect_to performance_histories_path, alert: e.message }
      format.json {
        render json: {
          status: 'Error',
          message: e.message
        }, status: :forbidden
      }
    end
  end

  private

  # == load_performance_history
  #
  # @author Moisés Reis
  # @category *Utility*
  #
  # Utility:: This private method finds a single performance history record in the
  #           database using the ID from the web request. It stores the record for
  #           use by other controller methods.
  #
  # Attributes:: - *params[:id]* @integer - The identifier of the record being requested.
  #
  def load_performance_history
    @performance_history = PerformanceHistory.includes(:portfolio, fund_investment: :investment_fund)
                                             .find(params[:id])
  end

  # == authorize_performance_history
  #
  # @author Moisés Reis
  # @category *Security*
  #
  # Security:: This private method checks the current action being performed
  #            and verifies the user's permissions (**read** or **manage**)
  #            on the loaded performance history record.
  #
  # Attributes:: - *action_name* @string - The name of the current controller action (e.g., 'show').
  #
  def authorize_performance_history

    # Explanation:: This specifically authorizes the user to read the record
    #               if the current action is 'show'.
    authorize! :read, @performance_history if action_name == 'show'

    # Explanation:: This specifically authorizes the user to manage (update or destroy)
    #               the record if the current action is 'update' or 'destroy'.
    authorize! :manage, @performance_history if %w[update destroy].include?(action_name)
  end

  # == performance_history_params
  #
  # @author Moisés Reis
  # @category *Security*
  #
  # Security:: This private method sanitizes all incoming data from the
  #            performance history form. It ensures that only specifically permitted
  #            fields are allowed to be saved to the database.
  #
  # Attributes:: - *params* @Hash - The raw data hash received from the user form submission.
  #
  def performance_history_params
    params.require(:performance_history).permit(
      :portfolio_id,
      :fund_investment_id,
      :period,
      :monthly_return,
      :yearly_return,
      :last_12_months_return
    )
  end
end