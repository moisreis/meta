# === economic_indices_controller.rb
#
# Description:: This controller manages web requests related to **EconomicIndex** records,
#               handling how the application creates, displays, updates, and removes
#               financial indicators like inflation or interest rates.
#
# Usage:: - *What* - This code acts as the manager for all interactions between the
#           user interface and the economic index data stored in the database.
#         - *How* - It receives requests, verifies if the user is allowed to perform
#           the action, and sends back the requested data in a digital format.
#         - *Why* - It provides a secure and organized way to manage the financial
#           benchmarks that the rest of the application uses for calculations.
#
# Attributes:: - *@economic_indices* [Collection] - A group of index records found.
#              - *@economic_index* [Object] - A single specific economic index record.
#
class EconomicIndicesController < ApplicationController

  # =============================================================
  #                        CONFIGURATION
  # =============================================================

  # This ensures that only people who have logged into their
  # accounts can access any of the information or actions
  # provided by this specific controller.
  before_action :authenticate_user!

  # This automatically searches for a specific index in the
  # database using the ID provided in the request before
  # showing, changing, or deleting it.
  before_action :set_economic_index, only: [
    :show,
    :edit,
    :update,
    :destroy
  ]

  # This acts as a security guard that only allows users with
  # administrator permissions to make changes, while letting
  # regular users just view the information.
  before_action :authorize_admin!, except: [
    :index,
    :show
  ]

  # =============================================================
  #                       PUBLIC METHODS
  # =============================================================

  # == index
  #
  # @author Moisés Reis
  #
  # This retrieves a list of all economic indexes, allowing
  # users to search for specific ones and see only a few
  # results at a time to keep the screen organized.
  #
  # Attributes:: - *@q* - A search object to find indices by name.
  #              - *@economic_indices* - The final paginated list of indices.
  def index

    # This defines the initial set of economic indices by getting all records
    # and ordering them alphabetically by name for easy browsing.
    base_scope = EconomicIndex.all.order(:name)

    # This initializes the search object using the **Ransack** gem,
    # applying any search criteria passed by the user in the web address.
    @q = base_scope.ransack(params[:q])

    # This variable stores the total number of records found in the database.
    # It allows the user to see exactly how many items exist in the list.
    @total_items = EconomicIndex.count

    # This executes the search query defined by **Ransack**, returning a
    # unique list of economic indices that match the search criteria.
    filtered_indices = @q.result(distinct: true)

    # This checks the web address for a specific column to sort by, defaulting
    # to sorting by the `name` if no sort column is specified.
    sort = params[:sort].presence || "name"

    # This checks the web address for a specific sort direction, defaulting
    # to ascending order (A-Z or lowest value first) if none is specified.
    direction = params[:direction].presence || "asc"

    # This applies the determined sort column and direction to the
    # filtered list of economic indices.
    sorted_indices = filtered_indices.order("#{sort} #{direction}")

    # This prepares the final data for the page, dividing the complete
    # list into pages of 14 items to improve performance and readability.
    @models = sorted_indices.page(params[:page]).per(14)

    # This sets the instance variable that the view expects, using the
    # paginated data prepared in the previous step.
    @economic_indices = @models

    respond_to do |format|
      format.html
    end
  end

  # == show
  #
  # @author Moisés Reis
  #
  # This displays the full details of a single economic index,
  # including its most recent value and a history of
  # changes if the user asks for them.
  #
  # Attributes:: - *@economic_index* - The specific index record being viewed.
  def show

    # This converts the database record into a format that
    # can be easily read and sent as a digital response.
    response_data = @economic_index.as_json

    # This checks if the user requested the latest value and,
    # if so, includes that specific number in the data.
    if params[:include_latest] == 'true'
      response_data[:latest_value] = @economic_index.latest_value
    end

    # This verifies if a date range was provided to filter
    # the history and adds those specific values to the response.
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      response_data[:values] = @economic_index.values_between(start_date, end_date)
    end

    respond_to do |format|
      format.html
      format.json { render json: response_data, status: :ok }
    end
  rescue ArgumentError

    # This handles cases where the dates provided are not
    # valid calendar days, redirecting the user safely.
    respond_to do |format|
      format.html { redirect_to economic_indices_path, alert: "Datas inválidas." }
      format.json { render json: { error: "Invalid date format" }, status: :unprocessable_entity }
    end
  end

  # == new
  #
  # @author Moisés Reis
  #
  # This prepares an empty record for a new economic index.
  # It provides the blank structure needed for the
  # creation form to appear correctly.
  #
  # Attributes:: - *@economic_index* - A fresh, unsaved index object.
  def new
    @economic_index = EconomicIndex.new
  end

  # == edit
  #
  # @author Moisés Reis
  #
  # This loads an existing index so it can be modified.
  # It fetches the data from the database to fill
  # in the fields on the editing page.
  #
  # Attributes:: - *@economic_index* - The existing index record to be updated.
  def edit
    @economic_index = EconomicIndex.find(params[:id])
  end

  # == create
  #
  # @author Moisés Reis
  #
  # This takes information provided by an administrator and
  # attempts to save a brand new economic index into
  # the application's database.
  #
  # Attributes:: - *@economic_index* - The set of data for the new index.
  def create
    @economic_index = EconomicIndex.new(economic_index_params)

    if @economic_index.save
      respond_to do |format|
        format.html { redirect_to @economic_index, notice: 'Índice econômico criado com sucesso.' }
        format.json { render json: @economic_index, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @economic_index.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # == update
  #
  # @author Moisés Reis
  #
  # This allows an administrator to change the details
  # of an existing index, such as correcting its
  # name or updating its description.
  #
  # Attributes:: - *@economic_index* - The unique record being updated.
  def update
    if @economic_index.update(economic_index_params)
      respond_to do |format|
        format.html { redirect_to @economic_index, notice: 'Índice atualizado com sucesso.' }
        format.json { render json: @economic_index, status: :ok }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @economic_index.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # == destroy
  #
  # @author Moisés Reis
  #
  # This permanently removes an economic index and all
  # of its historical records from the application
  # as requested by an administrator.
  #
  # Attributes:: - *@economic_index* - The unique record to remove.
  def destroy
    if @economic_index.destroy
      respond_to do |format|
        format.html { redirect_to economic_indices_path, notice: 'O índice econômico foi deletado com sucesso.' }
        format.json { render json: { message: 'O índice econômico foi deletado com sucesso' }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to economic_indices_path, alert: @economic_index.errors.full_messages.to_sentence }
        format.json { render json: { errors: @economic_index.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # =============================================================
  #                       HELPER UTILITIES
  # =============================================================

  private

  # == set_economic_index
  #
  # @author Moisés Reis
  #
  # This is a helper that finds the correct index in
  # the database using its ID before any specific
  # task is performed on it.
  #
  # Attributes:: - *@economic_index* - The record found in the database.
  def set_economic_index
    @economic_index = EconomicIndex.find(params[:id])
  rescue ActiveRecord::RecordNotFound

    # This sends a clear message saying the index
    # could not be found if the ID provided
    # does not exist in the system.
    render json: { error: 'O índice não foi encontrado.' }, status: :not_found
  end

  # == economic_index_params
  #
  # @author Moisés Reis
  #
  # This acts as a filter that only allows specific pieces
  # of information to be saved, preventing unauthorized
  # data from entering the system.
  #
  # Attributes:: - *name* - Allows the full name to be saved.
  #              - *abbreviation* - Allows the short code to be saved.
  #              - *description* - Allows the explanatory text to be saved.
  def economic_index_params
    params.require(:economic_index).permit(:name, :abbreviation, :description)
  end

  # == authorize_admin!
  #
  # @author Moisés Reis
  #
  # This check confirms if the current user has the
  # required permission level to make administrative
  # changes to the index data.
  #
  # Attributes:: - *current_user* - The person currently using the app.
  def authorize_admin!
    unless current_user.admin?

      # This blocks the user and sends a message stating
      # they do not have the right permissions to
      # perform this specific action.
      render json: { error: 'Unauthorized access' }, status: :forbidden
    end
  end
end