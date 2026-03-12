# === economic_index_histories_controller.rb
#
# Description:: This controller manages historical value records for **EconomicIndex** entries.
#               It handles listing and creation of time-series data points, allowing
#               administrators to maintain the historical values of economic indicators.
#
# Usage:: - *What* - This code block controls the listing and creation of economic index values,
#           allowing users to view and add historical data points for financial indicators.
#         - *How* - It uses search filters to display history records and provides a simple
#           form submission process to save new dates and values into the database.
#         - *Why* - It provides the necessary interface to build the historical datasets
#           that power performance calculations and trend analysis throughout the app.
#
# Attributes:: - *@economic_index_history* [Object] - The specific history record being created.
#              - *@economic_index_histories* [Collection] - The filtered and paginated list of history records.
#              - *@economic_index* [Object] - The parent economic index used for filtering.
#
class EconomicIndexHistoriesController < ApplicationController

  # This command confirms that a user is successfully logged into
  # the system before allowing access to any actions within this controller.
  # It ensures that only registered members can view or add data.
  before_action :authenticate_user!

  # This runs before all write operations to ensure only administrators
  # can create new historical economic data records. It prevents regular
  # users from modifying the critical historical values.
  before_action :authorize_admin!, except: [
    :index
  ]

  # This optionally loads the parent **EconomicIndex** if an index filter
  # is provided in the URL parameters, allowing scoped queries. It helps
  # organize the history by its specific economic indicator.
  before_action :load_economic_index, only: [
    :index,
    :new,
    :create
  ]

  # =============================================================
  #                       PUBLIC METHODS
  # =============================================================
  #
  # == index
  #
  # @author Moisés Reis
  #
  # This action retrieves and displays a list of historical value records.
  # It applies search, filtering by economic index, date range, and sorting
  # before displaying the results to the user in the index table.
  #
  # Attributes:: - *@models* - The paginated list of **EconomicIndexHistory** records.
  #              - *@economic_index_histories* - An alias for the paginated list used in the view.
  def index

    # This defines the initial set of history records. If a specific economic index
    # is selected, it scopes to that index; otherwise, it retrieves all records.
    base_scope = @economic_index ? @economic_index.economic_index_histories : EconomicIndexHistory.all

    # This joins the parent index data to the query to avoid loading them one by one.
    # It orders the records by date in descending order to show the latest values.
    base_scope = base_scope.includes(:economic_index).order(date: :desc)

    # This initializes the search object using the **Ransack** gem,
    # applying any search criteria passed by the user in the web address.
    @q = base_scope.ransack(params[:q])

    # This variable stores the total number of records found in the database.
    # It provides a count of every registered historical value to the user.
    @total_items = EconomicIndexHistory.count

    # This executes the search query defined by **Ransack**, returning a
    # unique list of history records that match the search criteria.
    filtered_histories = @q.result(distinct: true)

    # This checks the web address for a specific column to sort by, defaulting
    # to sorting by the date if no sort column is specified by the user.
    sort = params[:sort].presence || "date"

    # This checks the web address for a specific sort direction, defaulting
    # to descending order if none is specified in the request parameters.
    direction = params[:direction].presence || "desc"

    # This applies the determined sort column and direction to the
    # filtered list of history records to finalize the query.
    sorted_histories = filtered_histories.order("#{sort} #{direction}")

    # This prepares the final data for the page, dividing the complete
    # list into pages of 14 items to keep the dashboard clean.
    @models = sorted_histories.page(params[:page]).per(14)

    # This sets the instance variable that the index view expects to find.
    # It passes the finalized collection of records to be rendered in the table.
    @economic_index_histories = @models

    respond_to do |format|
      format.html
    end
  end

  # == new
  #
  # @author Moisés Reis
  #
  # This action creates a new, blank **EconomicIndexHistory** object.
  # This empty object is used by the form to gather input from the user for creation.
  #
  # Attributes:: - *@economic_index_history* - A new, unsaved history instance.
  def new

    # This initializes an empty record for the history table to be used in the form.
    # It prepares the fields so the user can type in the new date and value.
    @economic_index_history = EconomicIndexHistory.new

    # This pre-assigns the selected economic index to the new record if
    # the user came from a specific index page.
    @economic_index_history.economic_index = @economic_index if @economic_index
  end

  # == create
  #
  # @author Moisés Reis
  #
  # This action attempts to save a new historical value record to the
  # database. It validates the data and redirects back to the history list.
  #
  # Attributes:: - *economic_index_history_params* - The sanitized input data from the form.
  def create

    # This handles date construction and value sanitization to prepare
    # the history record for safe storage in the database.
    date = Date.new(
      params[:economic_index_history][:year_ref].to_i,
      params[:economic_index_history][:month_ref].to_i,
      1
    )

    # This creates a new history entry by cleaning up the number formatting
    # and combining the month and year into a single date field.
    @economic_index_history = EconomicIndexHistory.new(
      economic_index_id: params[:economic_index_history][:economic_index_id],
      date: date,
      value: params[:economic_index_history][:value].to_s.gsub(',', '.').to_d
    )

    if @economic_index_history.save
      redirect_to economic_index_histories_path notice: "Valor registrado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # =============================================================
  #                       PRIVATE METHODS
  # =============================================================

  private

  # == load_economic_index
  #
  # @author Moisés Reis
  #
  # This private method optionally loads the parent **EconomicIndex** record
  # if the `economic_index_id` parameter is present in the request.
  #
  # Attributes:: - *params[:economic_index_id]* - The parent index identifier.
  def load_economic_index

    # This searches the database for a specific economic indicator using its ID.
    # It is used to scope the history list so users only see values for one index.
    @economic_index = EconomicIndex.find(params[:economic_index_id]) if params[:economic_index_id].present?
  end

  # == authorize_admin!
  #
  # @author Moisés Reis
  #
  # This private method verifies that the current user has administrator
  # privileges required to create new historical economic data.
  #
  # Attributes:: - *current_user* - The currently authenticated user object.
  def authorize_admin!

    # This checks the admin status of the person currently logged in.
    # If they are not an administrator, it stops the action.
    unless current_user.admin?
      redirect_to root_path, alert: 'Acesso não autorizado. Apenas administradores podem registrar valores.'
    end
  end

  # == economic_index_history_params
  #
  # @author Moisés Reis
  #
  # This private method sanitizes all incoming data from the
  # history record form to ensure only permitted fields are saved.
  #
  # Attributes:: - *params* - The raw data hash received from the user form.
  def economic_index_history_params

    # This specifies exactly which fields, like values and dates, are safe
    # to be accepted and stored in the application's database.
    params.require(:economic_index_history).permit(
      :economic_index_id,
      :month_ref,
      :year_ref,
      :value
    )
  end
end