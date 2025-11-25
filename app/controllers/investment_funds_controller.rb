# === investment_funds_controller
#
# @author Moisés Reis
# @added 11/24/2025
# @package *Meta*
# @description This controller manages all available **InvestmentFund** records in the system.
#              It handles listing, viewing, creation, editing, and deletion, primarily
#              for administrative users. The explanations are in the present simple tense.
# @category *Controller*
#
# Usage:: - *[What]* This code block controls the master list of all investment funds that users can invest in.
#         - *[How]* It uses authorization checks via **CanCan** to manage who can create or modify funds, and it handles searching and sorting of the fund list.
#         - *[Why]* It provides a centralized and secure mechanism for managing the financial instruments offered by the application.
#
# Attributes:: - *@investment_fund* @object - The specific fund being handled (show, update, destroy).
#              - *@investment_funds* @collection - The filtered and paginated list of funds for the index view.
#
class InvestmentFundsController < ApplicationController

  # Explanation:: This command confirms that a user is successfully logged into
  #               the system before allowing access to any actions within this controller.
  before_action :authenticate_user!

  # Explanation:: This runs before viewing, editing, updating, or destroying a record. It finds
  #               the specific **InvestmentFund** from the database using the ID provided
  #               in the web address.
  before_action :load_investment_fund, only: [
    :show,
    :edit,
    :update,
    :destroy
  ]

  # Explanation:: This runs immediately after loading the record. It checks the user's
  #               permissions via **CanCan** to ensure they are authorized to perform
  #               the requested action (read, update, or destroy) on this specific fund.
  before_action :authorize_investment_fund, only: [
    :show,
    :update,
    :destroy
  ]

  # == index
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action retrieves and displays a list of all investment funds.
  #        It applies search, filtering, and sorting before displaying the results to the user.
  #
  # Attributes:: - *@models* - The paginated list of **InvestmentFund** records.
  #             - *@investment_funds* - An alias for the paginated list of funds used in the view.
  #
  def index

    # Explanation:: This defines the initial set of funds by getting all **InvestmentFund**
    #               records and ordering them by creation date, with the newest appearing first.
    base_scope = InvestmentFund.all.order(created_at: :desc)

    # Explanation:: This initializes the search object using the **Ransack** gem,
    #               applying any search criteria passed by the user in the web address.
    @q = base_scope.ransack(params[:q])

    # Explanation:: This executes the search query defined by **Ransack**, returning a
    #               unique list of investment funds that match the search criteria.
    filtered_and_scoped_funds = @q.result(distinct: true)

    # Explanation:: This checks the web address for a specific column to sort by, defaulting
    #               to sorting by the `cnpj` (Tax ID) if no sort column is specified.
    sort = params[:sort].presence || "cnpj"

    # Explanation:: This checks the web address for a specific sort direction, defaulting
    #               to ascending order (A-Z or lowest value first) if none is specified.
    direction = params[:direction].presence || "asc"

    # Explanation:: This applies the determined sort column and direction to the
    #               filtered list of investment funds.
    sorted_funds = filtered_and_scoped_funds.order("#{sort} #{direction}")

    # Explanation:: This prepares the final data for the page, dividing the complete
    #               list into pages of 2 items to improve performance and readability.
    @models = sorted_funds.page(params[:page]).per(2)

    # Explanation:: This sets the instance variable that the view expects, using the
    #               paginated data prepared in the previous step.
    @investment_funds = @models

    respond_to do |format|
      format.html
    end
  end

  # == show
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action prepares the specific fund record that was loaded earlier.
  #        It makes the data available for the view to display all its details to the user.
  #
  # Attributes:: - *@investment_fund* - The single fund object found by the `load_investment_fund` filter.
  #
  def show
  end

  # == new
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action creates a new, blank **InvestmentFund** object.
  #        This empty object is used by the form to gather input from the user for creation.
  #
  # Attributes:: - *@investment_fund* - A new, unsaved fund instance.
  #
  def new
    @investment_fund = InvestmentFund.new
  end

  # == edit
  #
  # @author Moisés Reis
  # @category *Edit*
  #
  # Edit:: This action prepares the view to display the existing fund's
  #        data, allowing the user to make changes to the record.
  #
  # Attributes:: - *@investment_fund* - The existing fund object loaded by the `before_action` filter.
  #
  def edit
  end

  # == create
  #
  # @author Moisés Reis
  # @category *Create*
  #
  # Create:: This action attempts to save a new investment fund record to the
  #          database. It first checks for creation permissions and returns
  #          a success or error message as a JSON response.
  #
  # Attributes:: - *investment_fund_params* - The sanitized input data from the user form.
  #
  def create
    @investment_fund = InvestmentFund.new(investment_fund_params)

    # Explanation:: This uses **CanCan** to verify that the current user has permission
    #               to create a new **InvestmentFund** record in the system.
    authorize! :create, InvestmentFund

    # Explanation:: This checks if the new fund object successfully passes
    #               all database validations and saves the record.
    if @investment_fund.save
      render json: {
        status: 'Success',
      }, status: :created
    else
      render json: { status: 'Error', errors: @investment_fund.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # == update
  #
  # @author Moisés Reis
  # @category *Update*
  #
  # Update:: This action attempts to modify an existing investment fund record
  #          with new data. It returns a success or error message as a JSON response.
  #
  # Attributes:: - *investment_fund_params* - The sanitized input data for updating the record.
  #
  def update
    if @investment_fund.update(investment_fund_params)
      render json: { status: 'Success' }
    else
      render json: { status: 'Error', errors: @investment_fund.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # == destroy
  #
  # @author Moisés Reis
  # @category *Delete*
  #
  # Delete:: This action deletes the investment fund record from the database.
  #          It returns a simple success confirmation as a JSON response.
  #
  # Attributes:: - *@investment_fund* - The fund object to be destroyed.
  #
  def destroy
    @investment_fund.destroy
    render json: { status: 'Success', message: 'Investment fund deleted' }, status: :ok
  end

  private

  # == load_investment_fund
  #
  # @author Moisés Reis
  # @category *Utility*
  #
  # Utility:: This private method finds a single fund record in the
  #           database using the ID from the web request. It stores the record for
  #           use by other controller methods.
  #
  # Attributes:: - *params[:id]* - The identifier of the fund record being requested.
  #
  def load_investment_fund
    @investment_fund = InvestmentFund.find(params[:id])
  end

  # == authorize_investment_fund
  #
  # @author Moisés Reis
  # @category *Security*
  #
  # Security:: This private method checks the current action being performed
  #            and verifies the user's permissions (**read** or **manage**)
  #            on the loaded investment fund record.
  #
  # Attributes:: - *action_name* - The name of the current controller action (e.g., 'show').
  #
  def authorize_investment_fund

    # Explanation:: This specifically authorizes the user to read the fund record
    #               if the current action is 'show'.
    authorize! :read, @investment_fund if action_name == 'show'

    # Explanation:: This specifically authorizes the user to manage (update or destroy)
    #               the fund record if the current action is 'update' or 'destroy'.
    authorize! :manage, @investment_fund if %w[update destroy].include?(action_name)
  end

  # == investment_fund_params
  #
  # @author Moisés Reis
  # @category *Security*
  #
  # Security:: This private method sanitizes all incoming data from the
  #            investment fund form. It ensures that only specifically permitted
  #            fields like `cnpj` and `fund_name` are allowed to be saved to the database.
  #
  # Attributes:: - *params* - The raw data hash received from the user form submission.
  #
  def investment_fund_params
    params.require(:investment_fund).permit(
      :cnpj,
      :fund_name,
      :originator_fund,
      :administrator_name
    )
  end
end