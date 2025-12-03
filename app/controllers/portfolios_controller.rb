# === portfolios_controller
#
# @author Moisés Reis
# @added 11/24/2025
# @package *Meta*
# @description This controller manages a user's **Portfolio** records, handling the
#              listing, creation, modification, and deletion of financial portfolios.
#              It also manages permissions for sharing portfolios with other users via
#              the **UserPortfolioPermission** model.
# @category *Controller*
#
# Usage:: - *[What]* This code block controls the set of financial portfolios owned by the user or shared with them.
#         - *[How]* It filters portfolios based on the current user's role and ID, handles search/sort requests, and manages the creation and updating of sharing permissions.
#         - *[Why]* It provides the secure and personalized environment for users to manage their investment holdings.
#
# Attributes:: - *@portfolio* @object - The specific portfolio being handled (show, update, destroy).
#              - *@portfolios* @collection - The filtered and paginated list of portfolios for the index view.
#
class PortfoliosController < ApplicationController

  # Explanation:: This command confirms that a user is successfully logged into
  #               the system before allowing access to any actions within this controller.
  before_action :authenticate_user!

  # Explanation:: This runs before actions like show, edit, update, or destroy.
  #               It calls the private method `set_portfolio` to find the specific **Portfolio**
  #               record from the database using the ID provided in the web address.
  before_action :set_portfolio, only: %i[ show edit update destroy ]

  # == index
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action retrieves and displays a list of financial portfolios.
  #        It applies search, filtering, and sorting based on user permissions before displaying the results.
  #
  # Attributes:: - *@models* - The paginated list of **Portfolio** records.
  #              - *@portfolios* - An alias for the paginated list of portfolios used in the view.
  #
  def index

    # Explanation:: This determines the initial set of portfolios to display. If the current user
    #               is an administrator, they see all portfolios; otherwise, they only see
    #               portfolios owned by or shared with them via a scope defined in the **Portfolio** model.
    base_scope =
      if current_user.admin?
        Portfolio.all
      else
        Portfolio.for_user(current_user)
      end

    # Explanation:: This initializes the search object using the **Ransack** gem,
    #               applying any search criteria passed by the user in the web address.
    @q = base_scope.ransack(params[:q])

    # Explanation:: This executes the search query defined by **Ransack**, returning a
    #               unique list of portfolios that match the search criteria.
    filtered_and_scoped_portfolios = @q.result(distinct: true)

    # Explanation:: This checks the web address for a specific column to sort by, defaulting
    #               to sorting by the primary `id` if no sort column is specified.
    sort = params[:sort].presence || "id"

    # Explanation:: This checks the web address for a specific sort direction, defaulting
    #               to ascending order (lowest ID first) if none is specified.
    direction = params[:direction].presence || "asc"

    # Explanation:: This applies the determined sort column and direction to the
    #               filtered list of portfolios.
    sorted_portfolios = filtered_and_scoped_portfolios.order("#{sort} #{direction}")

    # Explanation:: This prepares the final data for the page, dividing the complete
    #               list into pages of 20 items to improve performance and readability.
    @models = sorted_portfolios.page(params[:page]).per(20)

    # Explanation:: This sets the instance variable that the view expects, using the
    #               paginated data prepared in the previous step.
    @portfolios = @models

    respond_to do |format|
      format.html
      format.json { render json: PortfolioDatatable.new(params) }
    end
  end

  # == show
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action retrieves the portfolio belonging to the current user
  #        and prepares the monthly flow data so the view can display the
  #        portfolio's detailed evolution over time.
  #
  # Attributes:: - *@portfolio* - The single portfolio object found by the `set_portfolio` filter.
  #              - *@monthly_flows* - Aggregated flow values grouped by month
  #
  def show

    # Explanation:: Fetches the portfolio that belongs to the current user.
    #               The `for_user` scope ensures authorization at the query level,
    #               and `find` loads the specific record identified by `params[:id]`.
    @portfolio = Portfolio.for_user(current_user).find(params[:id])

    # Explanation:: Builds an array used to feed allocation charts.
    #               It loads each fund investment with its associated fund
    #               and extracts the fund name and its allocation percentage.
    @allocation_data = @portfolio.fund_investments.includes(:investment_fund).map do |fi|
      [fi.investment_fund.fund_name, fi.percentage_allocation || 0]
    end

    # Explanation:: Invokes a service-like method that computes the portfolio's
    #               monthly application and redemption totals for the past year,
    #               returning structured data ready for chart rendering.
    @monthly_flows = calculate_monthly_flows(@portfolio)
  end

  # == new
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action creates a new, blank **Portfolio** object.
  #        This empty object is used by the form to gather input from the user for creation.
  #
  # Attributes:: - *@portfolio* - A new, unsaved portfolio instance.
  #
  def new
    @portfolio = Portfolio.new
  end

  # == edit
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action prepares the view to display the existing portfolio's
  #        data, allowing the user to make changes to the record.
  #
  # Attributes:: - *@portfolio* - The existing portfolio object loaded by the `before_action` filter.
  #
  def edit
  end

  # == create
  #
  # @author Moisés Reis
  # @category *Create*
  #
  # Create:: This action attempts to save a new portfolio record to the database.
  #          If successful, it checks for sharing information and creates the necessary
  #          permissions before redirecting the user.
  #
  # Attributes:: - *portfolio_params* - The sanitized input data from the user form.
  #
  def create

    # Explanation:: This creates a new **Portfolio** object using the allowed parameters
    #               but temporarily excludes any sharing-specific parameters like the `shared_user_id`.
    @portfolio = Portfolio.new(portfolio_params.except(:shared_user_id))

    # Explanation:: This block handles the response format, either a traditional
    #               web page redirect (`format.html`) or a JSON response (`format.json`).
    respond_to do |format|

      # Explanation:: This checks if the new portfolio object successfully passes
      #               all database validations and saves the record.
      if @portfolio.save

        # Explanation:: This retrieves the ID of the user that the current user wants
        #               to share the newly created portfolio with, if present in the form data.
        shared_user_id = params.dig(:portfolio, :shared_user_id)

        # Explanation:: This retrieves the level of permission (e.g., 'read' or 'manage')
        #               to grant the shared user, defaulting to 'read' if not specified.
        permission_level = params.dig(:portfolio, :grant_crud_permission) || 'read'

        # Explanation:: This condition checks if a user ID for sharing was provided.
        #               If so, it proceeds to create the permission record.
        if shared_user_id.present?
          UserPortfolioPermission.create!(
            user_id: shared_user_id,
            portfolio_id: @portfolio.id,
            permission_level: permission_level
          )
        end
        format.html { redirect_to @portfolio, notice: "Portfolio was successfully created." }
        format.json { render :show, status: :created, location: @portfolio }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @portfolio.errors, status: :unprocessable_entity }
      end
    end
  end

  # == update
  #
  # @author Moisés Reis
  # @category *Update*
  #
  # Update:: This action attempts to modify an existing portfolio record.
  #          If successful, it updates the associated sharing permission for another user
  #          before redirecting the user.
  #
  # Attributes:: - *portfolio_params* - The sanitized input data for updating the record.
  #
  def update

    # Explanation:: This block handles the response format for the update request,
    #               either a traditional web page redirect (`format.html`) or a JSON response (`format.json`).
    respond_to do |format|

      # Explanation:: This attempts to update the portfolio object with the new data,
      #               excluding sharing parameters, and checks for validation success.
      if @portfolio.update(portfolio_params.except(:shared_user_id))

        # Explanation:: This retrieves the ID of the user that the current user wants
        #               to share the portfolio with, if present in the form data.
        shared_user_id = params.dig(
          :portfolio,
          :shared_user_id
        )

        # Explanation:: This retrieves the new permission level (e.g., 'read' or 'manage')
        #               to grant the shared user, defaulting to 'read' if not specified.
        permission_level = params.dig(
          :portfolio,
          :grant_crud_permission
        ) || 'read'

        # Explanation:: This checks if a user ID for sharing was provided.
        #               If so, it proceeds to create or update the permission record.
        if shared_user_id.present?
          UserPortfolioPermission.find_or_create_by!(
            user_id: shared_user_id,
            portfolio_id: @portfolio.id
          ) do |permission|
            permission.permission_level = permission_level
          end
        end
        format.html { redirect_to @portfolio, notice: "Portfolio was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @portfolio }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @portfolio.errors, status: :unprocessable_entity }
      end
    end
  end

  # == destroy
  #
  # @author Moisés Reis
  # @category *Delete*
  #
  # Delete:: This action deletes the portfolio record from the database.
  #          It also automatically destroys all associated records like
  #          **FundInvestment**s and **UserPortfolioPermission**s due to database dependencies.
  #
  # Attributes:: - *@portfolio* - The portfolio object to be destroyed.
  #
  def destroy
    @portfolio.destroy!
    respond_to do |format|
      format.html { redirect_to portfolios_path, notice: "Portfolio was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  # == calculate_monthly_flows
  #
  # @autho

  # @author Moisés Reis
  # @category *Read*
  #
  # Category:: Computes how much money went into and out of a portfolio each
  #            month. It prepares a clear, month-by-month summary so users
  #            can understand the portfolio’s financial movement over the year.
  #
  # Attributes:: - *@portfolio* - The portfolio used to gather monthly cash flows.
  #
  def calculate_monthly_flows(portfolio)

    # Explanation:: Initializes an empty array that will store the monthly
    #               applications and redemptions data for the past 12 months.
    monthly_data = []

    # Explanation:: Starts a loop that runs 12 times, once for each month
    #               going backwards from the current month.
    12.times do |i|

      # Explanation:: Computes the beginning of the month that occurred
      #               'i' months ago, used as the start of the date range.
      month_start = i.months.ago.beginning_of_month

      # Explanation:: Calculates the final day of the same month represented
      #               by month_start, completing the date range.
      month_end = month_start.end_of_month

      # Explanation:: Formats the month into a user-friendly label
      #               like "Jan/24", used for chart display.
      month_label = month_start.strftime('%b/%y')

      # Explanation:: Retrieves and sums all application financial values
      #               linked to the portfolio that fall within the month range.
      applications_sum = portfolio.fund_investments
                                  .joins(:applications)
                                  .where(applications: { cotization_date: month_start..month_end })
                                  .sum('applications.financial_value')

      # Explanation:: Retrieves and sums all redemption liquid values
      #               within the same date range for the portfolio.
      redemptions_sum = portfolio.fund_investments
                                 .joins(:redemptions)
                                 .where(redemptions: { cotization_date: month_start..month_end })
                                 .sum('redemptions.redeemed_liquid_value')

      # Explanation:: Adds a hash containing the month label and its
      #               corresponding application and redemption totals.
      monthly_data << {
        month: month_label,
        applications: applications_sum,
        redemptions: redemptions_sum
      }
    end

    # Explanation:: Reverses the array so months appear chronologically
    #               from oldest to most recent when displayed.
    monthly_data.reverse!

    # Explanation:: Prepares the final structure expected by the charting
    #               library, separating series for applications and redemptions.
    [
      { name: "Aplicações", data: monthly_data.map { |m| [m[:month], m[:applications]] } },
      { name: "Resgates", data: monthly_data.map { |m| [m[:month], m[:redemptions]] } }
    ]
  end

  # == load_portfolio
  #
  # @author Moisés Reis
  # @category *Utility*
  #
  # Utility:: This private method finds a single portfolio record in the
  #           database using the ID from the web request. It stores the record for
  #           use by other controller methods.
  #
  # Attributes:: - *params[:id]* - The identifier of the portfolio record being requested.
  #
  def load_portfolio
    @portfolio = Portfolio.find(params[:id])
  end

  # == authorize_portfolio
  #
  # @author Moisés Reis
  # @category *Security*
  #
  # Security:: This private method checks the current action being performed
  #            and verifies the user's permissions (**read** or **manage**)
  #            on the loaded portfolio record using **CanCan**.
  #
  # Attributes:: - *action_name* - The name of the current controller action (e.g., 'show').
  #
  def authorize_portfolio
    authorize! :read, @portfolio if action_name == 'show'
    authorize! :manage, @portfolio if %w[update destroy].include?(action_name)
  end

  # == set_portfolio
  #
  # @author Moisés Reis
  # @category *Utility*
  #
  # Utility:: This private method finds a single portfolio record in the
  #           database using the ID from the web request. This method is called by the
  #           `before_action` filter.
  #
  # Attributes:: - *params[:id]* - The identifier of the portfolio record being requested.
  #
  def set_portfolio
    @portfolio = Portfolio.find(params[:id])
  end

  # == portfolio_params
  #
  # @author Moisés Reis
  # @category *Security*
  #
  # Security:: This private method sanitizes all incoming data from the
  #            portfolio form. It ensures that only specifically permitted fields,
  #            like `name`, `user_id`, and `shared_user_id`, are allowed to be processed.
  #
  # Attributes:: - *params* - The raw data hash received from the user form submission.
  #
  def portfolio_params
    params.require(:portfolio).permit(
      :name,
      :user_id,
      :shared_user_id
    )
  end
end