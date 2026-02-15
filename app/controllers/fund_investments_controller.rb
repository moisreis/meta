# === fund_investments_controller
#
# @author Moisés Reis
# @added 11/24/2025
# @package *Meta*
# @description This controller manages the creation, listing, and detailed viewing
#              of a user's investments in specific funds. It ensures that users
#              can only access **FundInvestment** records they are authorized to see.
# @category *Controller*
#
# Usage:: - *[What]* This code block controls the records that link a user's
#           **Portfolio** to an **InvestmentFund** and tracks the total invested value and quotas held.
#         - *[How]* It uses authorization checks via **CanCan** to manage access,
#           and it handles filtering and sorting of the investment list for the index view.
#         - *[Why]* It provides a secure, organized view of the user's current
#           investment positions across various funds.
#
# Attributes:: - *@fund_investment* @object - The specific fund investment being handled (show, update, destroy).
#              - *@fund_investments* @collection - The filtered and paginated list of fund investments for the index view.
#
class FundInvestmentsController < ApplicationController

  include PdfExportable

  # Explanation:: This command confirms that a user is successfully logged into
  #               the system before allowing access to any actions within this controller.
  before_action :authenticate_user!

  # Explanation:: This runs before viewing, updating, or destroying a record. It finds
  #               the specific **FundInvestment** from the database using the ID provided
  #               in the web address.
  before_action :load_fund_investment, only: [
    :show,
    :update,
    :destroy
  ]

  # Explanation:: This runs immediately after loading the record. It checks the user's
  #               permissions via **CanCan** to ensure they are authorized to perform
  #               the requested action (read, update, or destroy) on this specific fund investment.
  before_action :authorize_fund_investment, only: [
    :show,
    :update,
    :destroy
  ]

  # Explanation:: This runs before displaying the new or create forms. It fetches the
  #               necessary related data, like available **InvestmentFund** and
  #               **Portfolio** options, for the form's dropdown menus.
  before_action :load_form_dependencies, only: [
    :new,
    :create
  ]

  # == index
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action retrieves and displays a list of all investment funds
  #        that the current user is permitted to see. It applies search,
  #        filtering, and sorting before displaying the results.
  #
  # Attributes:: - *params[:q]* - Search parameters used to filter the investment list.
  #             - *@fund_investments* - The final, filtered, and paginated list of investments.
  #
  def index

    # Explanation:: This defines the initial set of investments the user can access,
    #               which is all funds linked to portfolios the user manages.
    base_scope = accessible_fund_investments

    # Explanation:: This initializes the search object using the **Ransack** gem,
    #               applying any search criteria passed by the user.
    @q = base_scope.ransack(params[:q])

    # Explanation:: This variable stores the total number of records found in the database.
    #               It allows the user to see exactly how many items exist in the list.
    @total_items = FundInvestment.count

    # Explanation:: This executes the search query defined by Ransack, returning a
    #               unique list of fund investments that match the search criteria.
    filtered_and_scoped_funds = @q.result(distinct: true)

    # Explanation:: This checks the web address for a specific sort column, defaulting
    #               to sorting by the `total_invested_value` if none is specified.
    sort = params[:sort].presence || "total_invested_value"

    # Explanation:: This checks the web address for a specific sort direction, defaulting
    #               to descending order (highest value first) if none is specified.
    direction = params[:direction].presence || "desc"

    # Explanation:: This applies the determined sort column and direction to the
    #               filtered list of fund investments.
    sorted_funds = filtered_and_scoped_funds.order("#{sort} #{direction}")

    # Explanation:: This prepares the final data for the page, dividing the complete
    #               list into pages of 20 items to improve performance and readability.
    @fund_investments = sorted_funds.page(params[:page]).per(14)

    respond_to do |format|
      format.html # Renders index.html.erb
    end
  end

  # == show
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action prepares the specific fund investment record that was
  #        loaded earlier.
  #
  # Attributes:: - *@fund_investment* - The single fund investment object found by the `load_fund_investment` filter.
  #
  def show
  end

  # == new
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action creates a new, blank **FundInvestment** object. This
  #        empty object is used by the form to gather input from the user.
  #
  # Attributes:: - *@fund_investment* - A new, unsaved fund investment instance.
  #
  def new
    @fund_investment = FundInvestment.new
  end

  # == create
  #
  # @author Moisés Reis
  # @category *Create*
  #
  # Create:: This action attempts to save a new fund investment record to the
  #          database. It first checks for creation permissions and returns
  #          a success or error message.
  #
  # Attributes:: - *fund_investment_params* - The sanitized input data from the user form.
  #
  def create
    @fund_investment = FundInvestment.new(fund_investment_params)

    if @fund_investment.save
      redirect_to @fund_investment.portfolio, notice: "Investimento criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # == update
  #
  # @author Moisés Reis
  # @category *Update*
  #
  # Update:: This action attempts to modify an existing fund investment record
  #          with new data. It returns a success or error message.
  #
  # Attributes:: - *fund_investment_params* - The sanitized input data for updating the record.
  #
  def update
  end

  # == destroy
  #
  # @author Moisés Reis
  # @category *Delete*
  #
  # Delete:: This action deletes the fund investment record from the database.
  #          It returns a simple success confirmation.
  #
  # Attributes:: - *@fund_investment* - The fund investment object to be destroyed.
  #
  def destroy
    @fund_investment.destroy
  end

  private

  # == load_fund_investment
  #
  # @author Moisés Reis
  # @category *Utility*
  #
  # Utility:: This private method finds a single fund investment record in the
  #           database using the ID from the web request and stores it for
  #           use by other controller methods.
  #
  # Attributes:: - *params[:id]* - The identifier of the fund investment record.
  #
  def load_fund_investment
    @fund_investment = FundInvestment.find(params[:id])
  end

  # == authorize_fund_investment
  #
  # @author Moisés Reis
  # @category *Security*
  #
  # Security:: This private method checks the current action being performed
  #            and verifies the user's permissions (**read** or **manage**)
  #            on the loaded fund investment record.
  #
  # Attributes:: - *action_name* - The name of the current controller action (e.g., 'show').
  #
  def authorize_fund_investment

    # Explanation:: This specifically authorizes the user to read the fund investment
    #               if the current action is 'show'.
    authorize! :read, @fund_investment if action_name == 'show'

    # Explanation:: This specifically authorizes the user to manage (update or destroy)
    #               the fund investment if the current action is 'update' or 'destroy'.
    authorize! :manage, @fund_investment if %w[update destroy].include?(action_name)
  end

  # == fund_investment_params
  #
  # @author Moisés Reis
  # @category *Security*
  #
  # Security:: This private method sanitizes all incoming data from the
  #            fund investment form. It ensures that only specifically permitted
  #            fields are allowed to be saved to the database.
  #
  # Attributes:: - *params* - The raw data hash received from the user form submission.
  #
  def fund_investment_params
    params.require(:fund_investment).permit(
      :portfolio_id,
      :investment_fund_id,
      :total_invested_value,
      :total_quotas_held,
      :percentage_allocation
    )
  end

  # == accessible_fund_investments
  #
  # @author Moisés Reis
  # @category *Query*
  #
  # Query:: This private method retrieves all **FundInvestment** records that
  #         the current user has permission to access. It efficiently loads
  #         related portfolio and investment fund data.
  #
  # Attributes:: - *current_user* - The currently logged-in user object.
  #
  def accessible_fund_investments
    FundInvestment.accessible_to(current_user).includes(
      :portfolio,
      :investment_fund
    )
  end

  # == load_form_dependencies
  #
  # @author Moisés Reis
  # @category *Utility*
  #
  # Utility:: This private method fetches the necessary lists of related
  #           records for the creation form, specifically all available
  #           **InvestmentFund** options and the user's accessible portfolios.
  #
  # Attributes:: - *@investment_funds* - A collection of all available investment fund options.
  #
  def load_form_dependencies

    # Explanation:: This fetches a list of all existing investment funds available
    #               in the system for the user to choose from.
    @investment_funds = InvestmentFund.all

    # Explanation:: This fetches a list of all portfolios that the current user
    #               has access to, ensuring the new investment is linked correctly.
    @portfolios = accessible_portfolios
  end

  # == accessible_portfolios
  #
  # @author Moisés Reis
  # @category *Query*
  #
  # Query:: This private method retrieves the list of **Portfolio** records
  #         that belong to the current authenticated user.
  #
  # Attributes:: - *current_user* - The currently logged-in user object.
  #
  def accessible_portfolios
    current_user.portfolios
  end

  def pdf_export_title
    "Investimentos em Fundos"
  end

  def pdf_export_subtitle
    "Relatório de investimentos ativos"
  end

  def pdf_export_columns

    # Explanation:: This retrieves the helper proxy to access formatting methods.
    #               It allows the controller to use logic usually reserved for views.
    h = ActionController::Base.helpers

    [
      { header: "Fundo", key: ->(fi) { fi.investment_fund.fund_name } },
      { header: "CNPJ", key: ->(fi) { fi.investment_fund.cnpj } },
      { header: "Carteira", key: ->(fi) { fi.portfolio.name } },
      {
        header: "Cotas",
        # Explanation:: Instead of calling the method directly, we use the
        #               proxy 'h' to access the precision formatting logic.
        key: ->(fi) { h.number_with_precision(fi.total_quotas_held, precision: 2) },
        width: 80
      },
      {
        header: "Valor Investido",
        # Explanation:: We use 'view_context' to access your custom 'standard_currency'
        #               helper method and corrected the previous spelling error.
        key: ->(fi) { view_context.standard_currency(fi.total_invested_value) },
        width: 100
      },
      {
        header: "Alocação",
        key: ->(fi) { "#{fi.percentage_allocation}%" },
        width: 70
      }
    ]
  end

  def pdf_export_data
    FundInvestment.joins(:portfolio)
                  .where(portfolios: { user_id: current_user.id })
                  .includes(:investment_fund, :portfolio)
  end

  # == pdf_export_metadata
  #
  # @author Moisés Reis
  # @category *Utility*
  #
  # Utility:: This method compiles the summary information for the PDF report.
  #            It calculates the total sum of investments and formats it as currency.
  #
  # Attributes:: - *pdf_export_data* - The collection of records used to calculate the total.
  #
  def pdf_export_metadata
    # Explanation:: This retrieves the helper proxy to access formatting methods.
    #               It allows the controller to use logic usually reserved for views.
    h = ActionController::Base.helpers

    {
      'Usuário' => current_user.full_name,
      'Total investido' => h.number_to_currency(pdf_export_data.sum(:total_invested_value))
    }
  end
end