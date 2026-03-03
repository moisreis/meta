# === fund_investments_controller.rb
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
#                    **Portfolio** to an **InvestmentFund** and tracks totals.
#         - *[How]* It uses authorization checks via **CanCan** to manage access,
#                   handling the filtering and sorting of the investment list.
#         - *[Why]* It provides a secure, organized view of the user's current
#                   investment positions across various funds.
#
# Attributes:: - *[@fund_investment]* @object - the specific fund investment being handled
#              - *[@fund_investments]* @collection - the filtered list of fund investments
#

class FundInvestmentsController < ApplicationController

  include PdfExportable

  # This command confirms that a user is successfully logged into
  # the system before allowing access to any actions within this controller.
  before_action :authenticate_user!

  # This runs before viewing, updating, or destroying a record. It finds
  # the specific record using the ID provided in the web address.
  before_action :load_fund_investment, only: [
    :show,
    :update,
    :edit,
    :destroy
  ]

  # This checks the user's permissions via **CanCan** to ensure they are
  # authorized to perform the requested action on this specific investment.
  before_action :authorize_fund_investment, only: [
    :show,
    :update,
    :edit,
    :destroy
  ]

  # This fetches the necessary related data, like available **InvestmentFund**
  # and **Portfolio** options, for the form's dropdown menus.
  before_action :load_form_dependencies, only: [
    :new,
    :edit,
    :create
  ]

  # == index
  #
  # @author Moisés Reis
  #
  # This action retrieves and displays a list of all investment funds
  # that the current user is permitted to see. It applies search,
  # filtering, and sorting before displaying the results.
  #
  # Attributes:: - *@fund_investments* - the final, filtered, and paginated list of investments.
  #
  def index

    # This defines the initial set of investments the user can access,
    # which includes all funds linked to portfolios they manage.
    base_scope = accessible_fund_investments

    # This initializes the search object using the **Ransack** gem,
    # applying any search criteria passed by the user.
    @q = base_scope.ransack(params[:q])

    # This variable stores the total number of records found in the database.
    # It allows the user to see exactly how many items exist in the list.
    @total_items = FundInvestment.count

    # This executes the search query, returning a unique list of
    # fund investments that match the search criteria.
    filtered_and_scoped_funds = @q.result(distinct: true)

    # This checks the web address for a specific sort column, defaulting
    # to sorting by the total invested value if none is specified.
    sort = params[:sort].presence || "total_invested_value"

    # This checks the web address for a specific sort direction, defaulting
    # to descending order (highest value first) if none is specified.
    direction = params[:direction].presence || "desc"

    # This applies the determined sort column and direction to the
    # filtered list of fund investments.
    sorted_funds = filtered_and_scoped_funds.order("#{sort} #{direction}")

    # This prepares the final data for the page, dividing the complete
    # list into pages of 14 items to improve performance and readability.
    @fund_investments = sorted_funds.page(params[:page]).per(14)

    respond_to do |format|
      format.html
    end
  end

  # == show
  #
  # @author Moisés Reis
  #
  # This action prepares the specific fund investment record that was
  # loaded earlier for the detailed view page.
  #
  def show
  end

  # == new
  #
  # @author Moisés Reis
  #
  # This action creates a new, blank **FundInvestment** object. This
  # empty object is used by the form to gather input from the user.
  #
  def new
    @fund_investment = FundInvestment.new
  end

  # == create
  #
  # @author Moisés Reis
  #
  # This action attempts to save a new fund investment record to the
  # database. It returns a success or error message based on the result.
  #
  def create

    # This builds the new record from the sanitized information provided
    # by the user in the creation form.
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
  #
  # This action attempts to modify an existing fund investment record
  # with new data, ensuring the information remains valid.
  #
  def update
  end

  # == destroy
  #
  # @author Moisés Reis
  #
  # This action deletes the fund investment record from the database
  # and returns the user to the portfolio overview page.
  #
  def destroy

    # Captures the portfolio reference before the record is removed
    # so we know where to redirect the user.
    portfolio = @fund_investment.portfolio
    @fund_investment.destroy

    redirect_to portfolio, notice: "Investimento removido com sucesso."
  end

  # == edit
  #
  # @author Moisés Reis
  #
  # This prepares an existing record for the editing interface,
  # allowing users to change its parameters or allocation.
  #
  def edit
  end

  # == delete
  #
  # @author Moisés Reis
  #
  # This serves as a placeholder for a deletion confirmation view
  # if the application requires a non-standard removal process.
  #
  def delete
  end

  private

  # == load_fund_investment
  #
  # @author Moisés Reis
  #
  # This finds a single fund investment record in the database
  # using the unique ID provided in the web request.
  #
  def load_fund_investment
    @fund_investment = FundInvestment.find(params[:id])
  end

  # == authorize_fund_investment
  #
  # @author Moisés Reis
  #
  # This checks the current action and verifies the user's permissions
  # on the loaded record to prevent unauthorized access.
  #
  def authorize_fund_investment

    # This specifically authorizes the user to read the fund investment
    # if the current action is 'show'.
    authorize! :read, @fund_investment if action_name == 'show'

    # This authorizes the user to manage the investment if they are
    # trying to update or delete the record.
    authorize! :manage, @fund_investment if %w[update destroy].include?(action_name)
  end

  # == fund_investment_params
  #
  # @author Moisés Reis
  #
  # This sanitizes all incoming data from the form, ensuring only
  # specifically permitted fields are allowed to enter the database.
  #
  def fund_investment_params

    # This filters the input to accept only the specific fields needed
    # for a fund investment, such as values and allocations.
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
  #
  # This retrieves all fund records that the current user has permission
  # to access, including related portfolio and fund details.
  #
  def accessible_fund_investments

    # This scopes the search to records accessible to the user and
    # eager loads associations to prevent slow performance.
    FundInvestment.accessible_to(current_user).includes(
      :portfolio,
      :investment_fund
    )
  end

  # == market_value_on
  #
  # @author Moisés Reis
  #
  # This calculates the total value of the investment on a specific
  # past date based on the quota prices stored in the system.
  #
  def market_value_on
    fund_investment = FundInvestment.find(params[:id])
    date = Date.parse(params[:date])
    quota = fund_investment.investment_fund.quota_value_on(date)
    quotas = fund_investment.applications.sum(:number_of_quotas) -
             fund_investment.redemptions.sum(:redeemed_quotas)
    value = quota ? (quotas * quota).round(2) : nil

    render json: { value: value, quota: quota, date: date }
  end

  # == load_form_dependencies
  #
  # @author Moisés Reis
  #
  # This fetches the necessary lists of related records for the forms,
  # such as all available funds and the user's portfolios.
  #
  def load_form_dependencies

    # This fetches a list of all existing investment funds available
    # in the system for the user to choose from.
    @investment_funds = InvestmentFund.all

    # This fetches a list of all portfolios that the current user
    # has access to, ensuring the link is created correctly.
    @portfolios = accessible_portfolios
  end

  # == accessible_portfolios
  #
  # @author Moisés Reis
  #
  # This retrieves the list of portfolios that belong to the current
  # user to populate the selection fields in the interface.
  #
  def accessible_portfolios
    current_user.portfolios
  end

  # == pdf_export_title
  #
  # @author Moisés Reis
  #
  # This provides the main title used for the header of the
  # generated PDF reports for fund investments.
  #
  def pdf_export_title
    "Investimentos em Fundos"
  end

  # == pdf_export_subtitle
  #
  # @author Moisés Reis
  #
  # This provides the descriptive subtitle for the PDF reports,
  # identifying the content as a list of active investments.
  #
  def pdf_export_subtitle
    "Relatório de investimentos ativos"
  end

  # == pdf_export_columns
  #
  # @author Moisés Reis
  #
  # This defines the data table structure for the PDF export,
  # including labels, formatting logic, and column widths.
  #
  def pdf_export_columns

    # This retrieves the helper proxy to access formatting methods
    # normally used only in the web view.
    h = ActionController::Base.helpers

    [
      { header: "Fundo", key: ->(fi) { fi.investment_fund.fund_name } },
      { header: "CNPJ", key: ->(fi) { fi.investment_fund.cnpj } },
      { header: "Carteira", key: ->(fi) { fi.portfolio.name } },
      {
        header: "Cotas",
        # Accesses decimal formatting logic through the helper proxy.
        key: ->(fi) { h.number_with_precision(fi.total_quotas_held, precision: 2) },
        width: 80
      },
      {
        header: "Valor Investido",
        # Uses the view context to access your custom currency helper.
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

  # == pdf_export_data
  #
  # @author Moisés Reis
  #
  # This collects all the records that should be included in
  # the PDF file, filtering them by the current user's ID.
  #
  def pdf_export_data
    FundInvestment.joins(:portfolio)
                  .where(portfolios: { user_id: current_user.id })
                  .includes(:investment_fund, :portfolio)
  end

  # == pdf_export_metadata
  #
  # @author Moisés Reis
  #
  # This compiles the summary information for the PDF report,
  # such as the user's name and the total sum of investments.
  #
  def pdf_export_metadata

    # Accesses general currency formatting through the helper proxy.
    h = ActionController::Base.helpers

    {
      'Usuário' => current_user.full_name,
      'Total investido' => h.number_to_currency(pdf_export_data.sum(:total_invested_value))
    }
  end
end