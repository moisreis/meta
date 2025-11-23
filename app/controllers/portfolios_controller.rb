# === portfolios_controller
#
# @author Moisés Reis
# @added 11/13/2025
# @package *Meta*
# @description Defines the controller that manages portfolio records.
#              Uses shared behaviors from **ApplicationController** and ensures that
#              access control, filtering, sorting, and pagination remain consistent
#              across all dashboard and administrative flows.
# @category *Controller*
#
# Usage:: - *[what]* This controller handles CRUD actions for **Portfolio** records.
#         - *[how]* It authenticates users, loads portfolios, applies search and sort logic through **Ransack**,
#                   paginates results, and responds to both HTML and JSON formats.
#         - *[why]* It structures how portfolio data moves between the application and the user interface,
#                   ensuring clear separation of concerns and predictable behavior for user-facing features.
#
# Attributes:: - *@portfolio* @object - stores the portfolio in context for actions
#              - *@models* @collection - stores paginated portfolio records
#              - *@q* @object - holds the Ransack search object
#              - *@portfolios* @collection - alias for *@models* for view access
#
class PortfoliosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_portfolio, only: %i[ show edit update destroy ]

  # [Action] Lists portfolios with filtering, sorting, and pagination.
  #          Resolves data visibility based on user role and returns HTML or JSON.
  def index
    # [Scope] Defines the initial dataset based on whether the user has administrative access.
    base_scope =
      if current_user.admin?
        Portfolio.all
      else
        Portfolio.for_user(current_user)
      end

    # [Search] Builds a Ransack search object using the filtered portfolio scope.
    @q = base_scope.ransack(params[:q])

    # [Search] Applies the Ransack filters and returns a distinct result set.
    filtered_and_scoped_portfolios = @q.result(distinct: true)

    # [Sorting] Extracts the sorting column from parameters or defaults to the portfolio ID.
    sort = params[:sort].presence || "id"

    # [Sorting] Extracts the sorting direction from parameters or defaults to ascending order.
    direction = params[:direction].presence || "asc"

    # [Sorting] Applies sorting rules to the filtered collection.
    sorted_portfolios = filtered_and_scoped_portfolios.order("#{sort} #{direction}")

    # [Pagination] Splits the sorted results into pages with a fixed number of items per page.
    @models = sorted_portfolios.page(params[:page]).per(20)

    # [View] Exposes the paginated dataset to the views using an intuitive alias.
    @portfolios = @models

    respond_to do |format|
      format.html
      format.json { render json: PortfolioDatatable.new(params) }
    end
  end

  # [Action] Shows a specific portfolio using the loaded instance.
  def show
  end

  # [Action] Initializes a new portfolio instance for the form.
  def new
    @portfolio = Portfolio.new
  end

  # [Action] Renders the edit form for the selected portfolio.
  def edit
  end

  # [Action] Handle portfolio creation request
  def create
    @portfolio = Portfolio.new(portfolio_params.except(:shared_user_id))
    respond_to do |format|
      if @portfolio.save
        shared_user_id = params.dig(:portfolio, :shared_user_id)
        permission_level = params.dig(:portfolio, :grant_crud_permission) || 'read'

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

  # [Action] Handle portfolio updating request
  def update
    respond_to do |format|
      if @portfolio.update(portfolio_params.except(:shared_user_id))
        shared_user_id = params.dig(:portfolio, :shared_user_id)
        permission_level = params.dig(:portfolio, :grant_crud_permission) || 'read'

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

  # [Action] Destroys a portfolio and redirects to the index.
  def destroy
    @portfolio.destroy!
    respond_to do |format|
      format.html { redirect_to portfolios_path, notice: "Portfolio was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  # [Helper] Loads a portfolio by ID for legacy or auxiliary use.
  def load_portfolio
    @portfolio = Portfolio.find(params[:id])
  end

  # [Helper] Authorizes portfolio access depending on the action.
  def authorize_portfolio
    authorize! :read, @portfolio if action_name == 'show'
    authorize! :manage, @portfolio if %w[update destroy].include?(action_name)
  end

  # [Helper] Loads the portfolio using strong parameter extraction.
  def set_portfolio
    @portfolio = Portfolio.find(params[:id])
  end

  # [Helper] Whitelists allowed parameters to ensure secure updates.
  def portfolio_params
    params.require(:portfolio).permit(:name, :user_id, :shared_user_id)
  end
end