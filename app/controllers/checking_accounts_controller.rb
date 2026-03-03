# === checking_accounts_controller.rb
#
# @author Moisés Reis
# @added 03/03/2026
# @package *Meta*
# @description This controller manages the digital records of bank balances
#              within a specific **Portfolio**. It tracks how much money is
#              held in various institutions for specific months to help
#              calculate the total net worth of a user's assets.
# @category *Controller*
#
# Usage:: - *[What]* A management tool for recording and updating the monthly
#           balances of different checking accounts.
#         - *[How]* It organizes accounts by a reference month and institution,
#           ensuring only authorized owners can make changes.
#         - *[Why]* Accurate bank balance tracking is essential for a complete
#           overview of a portfolio's total financial health.
#
# Attributes:: - *[@portfolio]* @model - the parent portfolio owning the accounts
#              - *[@checking_accounts]* @collection - the list of bank records
#              - *[@total_balance]* @decimal - the sum of all account balances
#
# @see FundInvestment
# @see Portfolio
#
class CheckingAccountsController < ApplicationController

  # This security check ensures that only users who have logged
  # into the system can view or manage bank account records.
  before_action :authenticate_user!

  # This step identifies the specific portfolio being viewed to
  # ensure all bank accounts stay grouped correctly.
  before_action :set_portfolio

  # This verifies if the user has the high-level permission needed
  # to create or change information instead of just reading it.
  before_action :authorize_write!, only: %i[new create edit update destroy]

  # This automatically finds the specific bank record requested
  # so its details can be shown, edited, or removed.
  before_action :set_checking_account, only: %i[show edit update destroy]

  # == index
  #
  # @author Moisés Reis
  #
  # This action displays a list of all bank accounts for a chosen month.
  # It calculates the total balance for that period and provides a
  # list of other months the user can switch to for comparison.
  #
  # Attributes:: - *@reference_date* - the specific month being viewed.
  #              - *@available_months* - a list of dates with existing records.
  #
  def index

    # Determines which month the user wants to see, defaulting to today.
    @reference_date = parse_reference_date(params[:month])

    # Prepares the list of accounts for that month with search filters.
    @q = @portfolio.checking_accounts
                   .for_period(@reference_date.end_of_month)
                   .ransack(params[:q])

    # Organizes the final list by bank name and limits the page size.
    @checking_accounts = @q.result
                           .order(:institution, :name)
                           .page(params[:page]).per(14)

    # Aggregates the total balance across all accounts for the resolved period.
    @total_balance = @portfolio.checking_accounts
                               .for_period(@reference_date.end_of_month)
                               .sum(:balance)

    # Collects up to 24 distinct reference months for the period-selector UI.
    @available_months = @portfolio.checking_accounts
                                  .distinct
                                  .order(reference_date: :desc)
                                  .limit(24)
                                  .pluck(:reference_date)

    respond_to do |format|
      format.html
    end
  end

  # == show
  #
  # @author Moisés Reis
  #
  # This action displays the specific details for one bank account,
  # showing the institution, account number, and current balance.
  #
  def show
  end

  # == new
  #
  # @author Moisés Reis
  #
  # This prepares a fresh bank account entry with default values like
  # the current month and currency, ready for the user to fill in.
  #
  def new

    # Initializes a new record with standard defaults for easier entry.
    @checking_account = @portfolio.checking_accounts.new(
      reference_date: Date.current.end_of_month,
      currency: 'BRL'
    )
  end

  # == edit
  #
  # @author Moisés Reis
  #
  # This gathers the existing information of a bank account and
  # presents it in a form so the user can make updates or corrections.
  #
  def edit
  end

  # == create
  #
  # @author Moisés Reis
  #
  # This saves a new bank record to the database and sends the user
  # back to the list of accounts for the month they just recorded.
  #
  def create

    # Builds a new account record using the data provided in the form.
    @checking_account = @portfolio.checking_accounts.new(checking_account_params)

    respond_to do |format|
      if @checking_account.save
        format.html do
          # Redirects to the specific month view after a successful save.
          redirect_to portfolio_checking_accounts_path(
                        @portfolio,
                        month: @checking_account.reference_date.strftime('%Y-%m')
                      ),
                      notice: "Conta corrente criada com sucesso."
        end
      else
        # Shows the form again if there were errors in the information.
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # == update
  #
  # @author Moisés Reis
  #
  # This applies changes to an existing bank record, ensuring all
  # values are correct before finalizing the update in the system.
  #
  def update
    respond_to do |format|
      if @checking_account.update(checking_account_params)
        format.html do
          # Takes the user back to the details page once the change is saved.
          redirect_to portfolio_checking_account_path(@portfolio, @checking_account),
                      notice: "Conta corrente atualizada com sucesso.",
                      status: :see_other
        end
      else
        # Re-renders the edit form if any validation errors occurred.
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # == destroy
  #
  # @author Moisés Reis
  #
  # This permanently removes a bank account record from the portfolio
  # and returns the user to the list for the same month they were in.
  #
  def destroy

    # Captures the date first so we know where to send the user back to.
    month_param = @checking_account.reference_date.strftime('%Y-%m')
    @checking_account.destroy!

    respond_to do |format|
      format.html do
        # Returns to the monthly list to show the record has been removed.
        redirect_to portfolio_checking_accounts_path(@portfolio, month: month_param),
                    notice: "Conta corrente removida com sucesso.",
                    status: :see_other
      end
    end
  end

  private

  # == set_portfolio
  #
  # @author Moisés Reis
  #
  # This finds the correct portfolio based on the ID in the link,
  # ensuring the user actually has permission to access it.
  #
  def set_portfolio

    # Admin users see all, while regular users only see their own data.
    base_scope = current_user.admin? ? Portfolio.all : Portfolio.for_user(current_user)
    @portfolio = base_scope.find(params[:portfolio_id])
  end

  # == authorize_write!
  #
  # @author Moisés Reis
  #
  # This blocks users who are just "guests" in a portfolio from
  # changing any bank data, keeping the information secure.
  #
  def authorize_write!
    return if current_user.admin?
    return if @portfolio.user_id == current_user.id

    # Stops the action and warns the user if they lack permission.
    redirect_to portfolio_checking_accounts_path(@portfolio),
                alert: "Você não tem permissão para modificar as contas correntes desta carteira."
  end

  # == set_checking_account
  #
  # @author Moisés Reis
  #
  # This locates a specific bank record within the current portfolio
  # to make sure users can't access accounts from other portfolios.
  #
  def set_checking_account

    # Limits the search to only accounts owned by the current portfolio.
    @checking_account = @portfolio.checking_accounts.find(params[:id])
  end

  # == checking_account_params
  #
  # @author Moisés Reis
  #
  # This cleans and prepares the data from the web form, making
  # sure dates are set to the last day of the month for consistency.
  #
  def checking_account_params

    # Specifies exactly which fields are allowed to be saved.
    permitted = params.require(:checking_account).permit(
      :name,
      :institution,
      :account_number,
      :balance,
      :reference_date,
      :currency,
      :notes
    )

    # Automatically moves the date to the end of the month if provided.
    if permitted[:reference_date].present?
      begin
        permitted[:reference_date] = Date.parse(permitted[:reference_date].to_s).end_of_month
      rescue Date::Error
      end
    end

    permitted
  end

  # == parse_reference_date
  #
  # @author Moisés Reis
  #
  # This takes the month selected by the user and turns it into a
  # date format the computer can use to filter the account list.
  #
  def parse_reference_date(month_param)

    # Returns the end of the current month if no selection was made.
    return Date.current.end_of_month if month_param.blank?

    # Converts a text like "2026-03" into a proper calendar date.
    Date.strptime("#{month_param}-01", '%Y-%m-%d').end_of_month
  rescue Date::Error
    Date.current.end_of_month
  end
end