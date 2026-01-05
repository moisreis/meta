# === economic_index_histories_controller.rb
#
# @author Moisés Reis
# @added 12/4/2025
# @package *Meta*
# @description This controller manages historical value records for **EconomicIndex** entries.
#              It handles listing and creation of time-series data points, allowing
#              administrators to maintain the historical values of economic indicators.
# @category *Controller*
#
# Usage:: - *[What]* This code block controls the listing and creation of economic index values,
#           allowing users to view and add historical data points for financial indicators.
#         - *[How]* It uses search filters to display history records and provides a simple
#           form submission process to save new dates and values into the database.
#         - *[Why]* It provides the necessary interface to build the historical datasets
#           that power performance calculations and trend analysis throughout the app.
#
# Attributes:: - *@economic_index_history* @object - The specific history record being created.
#              - *@economic_index_histories* @collection - The filtered and paginated list of history records.
#              - *@economic_index* @object - The parent economic index used for filtering.
#
class EconomicIndexHistoriesController < ApplicationController

  # Explanation:: This command confirms that a user is successfully logged into
  #               the system before allowing access to any actions within this controller.
  #               It ensures that only registered members can view or add data.
  before_action :authenticate_user!

  # Explanation:: This runs before all write operations to ensure only administrators
  #               can create new historical economic data records. It prevents regular
  #               users from modifying the critical historical values.
  before_action :authorize_admin!, except: [
    :index
  ]

  # Explanation:: This optionally loads the parent **EconomicIndex** if an index filter
  #               is provided in the URL parameters, allowing scoped queries. It helps
  #               organize the history by its specific economic indicator.
  before_action :load_economic_index, only: [
    :index,
    :new,
    :create
  ]

  # == index
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action retrieves and displays a list of historical value records.
  #        It applies search, filtering by economic index, date range, and sorting
  #        before displaying the results to the user in the index table.
  #
  # Attributes:: - *@models* - The paginated list of **EconomicIndexHistory** records.
  #              - *@economic_index_histories* - An alias for the paginated list used in the view.
  #
  def index

    # Explanation:: This defines the initial set of history records. If a specific economic index
    #               is selected, it scopes to that index; otherwise, it retrieves all records.
    #               It serves as the starting point for the data list.
    base_scope = @economic_index ? @economic_index.economic_index_histories : EconomicIndexHistory.all

    # Explanation:: This joins the parent index data to the query to avoid loading them one by one.
    #               It orders the records by date in descending order to show the latest values.
    #               This ensures the table always shows the most recent data first.
    base_scope = base_scope.includes(:economic_index).order(date: :desc)

    # Explanation:: This initializes the search object using the **Ransack** gem,
    #               applying any search criteria passed by the user in the web address.
    #               It allows users to find specific dates or values within the history.
    @q = base_scope.ransack(params[:q])

    # Explanation:: This variable stores the total number of records found in the database.
    #               It provides a count of every registered historical value to the user.
    #               It is used to show the total dataset size on the dashboard.
    @total_items = EconomicIndexHistory.count

    # Explanation:: This executes the search query defined by **Ransack**, returning a
    #               unique list of history records that match the search criteria.
    #               It filters the rows based on the user's current search input.
    filtered_histories = @q.result(distinct: true)

    # Explanation:: This checks the web address for a specific column to sort by, defaulting
    #               to sorting by the date if no sort column is specified by the user.
    #               It ensures the table has a consistent order upon loading.
    sort = params[:sort].presence || "date"

    # Explanation:: This checks the web address for a specific sort direction, defaulting
    #               to descending order if none is specified in the request parameters.
    #               It controls whether the list goes from newest to oldest or vice versa.
    direction = params[:direction].presence || "desc"

    # Explanation:: This applies the determined sort column and direction to the
    #               filtered list of history records to finalize the query.
    #               It organizes the data exactly as the user requested in the UI.
    sorted_histories = filtered_histories.order("#{sort} #{direction}")

    # Explanation:: This prepares the final data for the page, dividing the complete
    #               list into pages of 14 items to keep the dashboard clean.
    #               It improves speed by not loading the entire history at once.
    @models = sorted_histories.page(params[:page]).per(14)

    # Explanation:: This sets the instance variable that the index view expects to find.
    #               It passes the finalized collection of records to be rendered in the table.
    @economic_index_histories = @models

    respond_to do |format|
      format.html
    end
  end

  # == new
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action creates a new, blank **EconomicIndexHistory** object.
  #        This empty object is used by the form to gather input from the user for creation.
  #
  # Attributes:: - *@economic_index_history* - A new, unsaved history instance.
  #
  def new

    # Explanation:: This initializes an empty record for the history table to be used in the form.
    #               It prepares the fields so the user can type in the new date and value.
    @economic_index_history = EconomicIndexHistory.new

    # Explanation:: This pre-assigns the selected economic index to the new record if
    #               the user came from a specific index page. It saves time by filling
    #               out the indicator field automatically.
    @economic_index_history.economic_index = @economic_index if @economic_index
  end

  # == create
  #
  # @author Moisés Reis
  # @category *Create*
  #
  # Create:: This action attempts to save a new historical value record to the
  #          database. It validates the data and redirects back to the history list.
  #
  # Attributes:: - *economic_index_history_params* - The sanitized input data from the form.
  #
  def create

    # Explanation:: This creates a new record using the safe data received from the web form.
    #               It maps the user's input to the correct database columns.
    @economic_index_history = EconomicIndexHistory.new(economic_index_history_params)

    # Explanation:: This checks if the new history record successfully passes all database
    #               rules and saves it. If successful, it sends the user back to the
    #               main list with a confirmation message.
    if @economic_index_history.save
      redirect_to economic_index_histories_path, notice: 'Valor histórico registrado com sucesso.'
    else

      # Explanation:: This handles cases where the data is incorrect, such as a missing value.
      #               It reloads the creation form and shows the error messages to the user.
      render :new, status: :unprocessable_entity
    end
  end

  private

  # == load_economic_index
  #
  # @author Moisés Reis
  # @category *Utility*
  #
  # Utility:: This private method optionally loads the parent **EconomicIndex** record
  #           if the `economic_index_id` parameter is present in the request.
  #           This allows filtering and scoping of history records to a specific index.
  #
  # Attributes:: - *params[:economic_index_id]* - The parent index identifier.
  #
  def load_economic_index

    # Explanation:: This searches the database for a specific economic indicator using its ID.
    #               It is used to scope the history list so users only see values for one index.
    @economic_index = EconomicIndex.find(params[:economic_index_id]) if params[:economic_index_id].present?
  end

  # == authorize_admin!
  #
  # @author Moisés Reis
  # @category *Security*
  #
  # Security:: This private method verifies that the current user has administrator
  #            privileges required to create new historical economic data.
  #            Regular users are blocked from adding data they shouldn't.
  #
  # Attributes:: - *current_user* - The currently authenticated user object.
  #
  def authorize_admin!

    # Explanation:: This checks the admin status of the person currently logged in.
    #               If they are not an administrator, it stops the action and
    #               sends them back to the home page with an alert.
    unless current_user.admin?
      redirect_to root_path, alert: 'Acesso não autorizado. Apenas administradores podem registrar valores.'
    end
  end

  # == economic_index_history_params
  #
  # @author Moisés Reis
  # @category *Security*
  #
  # Security:: This private method sanitizes all incoming data from the
  #            history record form. It ensures that only specifically permitted
  #            fields are allowed to be saved to the database.
  #
  # Attributes:: - *params* - The raw data hash received from the user form submission.
  #
  def economic_index_history_params

    # Explanation:: This defines which parts of the form data are allowed to enter the database.
    #               It protects the system by ignoring any unexpected or malicious fields.
    params.require(:economic_index_history).permit(
      :economic_index_id,
      :date,
      :value
    )
  end
end