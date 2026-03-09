# === applications_controller.rb
#
# @author Moisés Reis
# @added 03/03/2026
# @package *Meta*
# @description This controller manages the creation, removal, and listing of
#              investment records. It ensures that when money is added or
#              removed, the total balances in the **FundInvestment** and
#              **Application** models stay perfectly synchronized.
# @category *Controller*
#
# Usage:: - *[What]* A management tool for tracking individual financial
#           deposits made into different investment funds.
#         - *[How]* It calculates shares based on daily prices and updates
#           the main portfolio totals using secure database steps.
#         - *[Why]* It provides a clear history of investments while keeping
#           all financial calculations accurate and automated.
#
# Attributes:: - *[@applications]* @collection - the list of investment records
#              - *[@application]* @model - a single investment entry
#              - *[@fund_investments]* @collection - available funds for selection
#
class ApplicationsController < ApplicationController
  # This security check ensures that only users who have logged
  # into the system can view or manage investment records.
  before_action :authenticate_user!

  # This step automatically finds the specific investment record
  # requested so its details can be shown, edited, or deleted.
  before_action :load_application, only: [
    :show,
    :edit,
    :update,
    :destroy
  ]

  # This verifies that the logged-in user actually has the right
  # permission to view or change this specific investment data.
  before_action :authorize_application, only: [
    :show,
    :edit,
    :update,
    :destroy
  ]

  # This prepares a list of available funds so the user can
  # easily pick one when creating or editing an investment.
  before_action :load_form_dependencies, only: [
    :new,
    :edit,
    :create
  ]

  # == index
  #
  # @author Moisés Reis
  #
  # This action gathers all the investments the user is allowed to see,
  # organizes them into a list, and allows for searching and sorting.
  # It makes sure the user only sees data from their own portfolios.
  #
  # Attributes:: - *@q* - the search object used to filter the list.
  #              - *@total_items* - the total number of records found.
  #
  def index
    # Collects the IDs of every fund investment the current user is allowed to read.
    fund_investments_ids = FundInvestment.accessible_to(current_user).select(:id)

    # Builds the base scope: applications belonging to accessible funds,
    # with their portfolio and investment_fund associations eager-loaded.
    base_scope = Application.where(fund_investment_id: fund_investments_ids)
                            .includes(fund_investment: [
                              :portfolio,
                              :investment_fund
                            ])

    # Initialises the Ransack search object from the query string parameters.
    @q = base_scope.ransack(params[:q])

    # Executes the Ransack query, removing duplicate rows.
    filtered_applications = @q.result(distinct: true)

    # Stores the unfiltered count so the view can display the total record count.
    @total_items = Application.count

    # Resolves the sort column, falling back to request_date when absent.
    sort = params[:sort].presence || "request_date"

    # Resolves the sort direction, falling back to descending order when absent.
    direction = params[:direction].presence || "desc"

    # Applies the resolved sort column and direction to the filtered result set.
    sorted_applications = filtered_applications.order("#{sort} #{direction}")

    # Paginates the sorted result at 14 records per page.
    @applications = sorted_applications.page(params[:page]).per(14)

    respond_to do |format|
      format.html
    end
  end

  # == show
  #
  # @author Moisés Reis
  #
  # This displays all the specific details of a single investment,
  # including calculated performance metrics and verification checks.
  # It helps the user see if the investment data is consistent.
  #
  def show
    # Prepares specialized math and status checks for the display page.
    prepare_application_metrics

    respond_to do |format|
      format.html
    end
  end

  # == new
  #
  # @author Moisés Reis
  #
  # This sets up a fresh, empty investment record so the system
  # can display a blank form for the user to fill out.
  #
  def new
    # Creates a new empty record to be filled in by the form.
    @application = Application.new
  end

  # == edit
  #
  # @author Moisés Reis
  #
  # This prepares an existing investment record so the user can
  # view its current information and make any necessary changes.
  #
  def edit
  end

  def create
    @application = Application.new
    portfolio = Portfolio.find(application_params[:portfolio_id])
    fund = InvestmentFund.find(application_params[:investment_fund_id])

    authorize! :manage, portfolio

fund_investment = FundInvestment.find_or_create_by!(
  investment_fund: fund,
  portfolio: portfolio
) do |fi|
  fi.skip_allocation_validation = true  # ← aqui
  fi.percentage_allocation = 0
  fi.total_invested_value = 0
  fi.total_quotas_held = 0
end

    @application = Application.new(
      application_params.except(:portfolio_id, :investment_fund_id)
                        .merge(fund_investment: fund_investment)
    )

    if @application.cotization_date.present? && @application.financial_value.present?
      quota_value = fund.quota_value_on(@application.cotization_date)

      unless quota_value
        @application.errors.add(:cotization_date, "Não há cota disponível para esta data")
        return render :new, status: :unprocessable_entity
      end

      @application.quota_value_at_application = quota_value
      @application.number_of_quotas = BigDecimal(@application.financial_value.to_s) / quota_value
    end

    ActiveRecord::Base.transaction do
      fund_investment.skip_allocation_validation = true
      @application.save!
      update_fund_investment_after_create(fund_investment)
      PortfolioAllocationCalculator.recalculate!(portfolio)
    end

    flash[:notice] = "Investimento criado com sucesso."
    redirect_to portfolio_path(portfolio)

  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Application save failed: #{e.record.errors.full_messages}"
    render :new, status: :unprocessable_entity
  rescue CanCan::AccessDenied
    redirect_to portfolios_path
  end

  # == update
  #
  # @author Moisés Reis
  #
  # This prevents users from making direct edits to investment records,
  # forcing them to delete and recreate them to ensure data integrity.
  # This keeps the financial history clean and error-free.
  #
  def update
    # Blocks the update and sends the user back to the details page.
    redirect_to application_path(@application), status: :method_not_allowed
  end

  # == destroy
  #
  # @author Moisés Reis
  #
  # This removes an investment record and subtracts its value and
  # shares from the fund totals, keeping the overall balance accurate.
  # It acts like an "undo" button for a financial deposit.
  #
  def destroy
    fund_investment = @application.fund_investment

    # Subtracts the values and removes the record in one secure operation.
    ActiveRecord::Base.transaction do
      update_fund_investment_before_destroy(fund_investment)
      @application.destroy!
    end

    flash[:notice] = "Investimento deletado com sucesso."

    # Sends the user back to the main fund page after the removal.
    redirect_to fund_investment_path(fund_investment.id), status: :see_other

  rescue ActiveRecord::RecordInvalid
    redirect_to application_path(@application)
  end

  private

  # == load_application
  #
  # @author Moisés Reis
  #
  # This searches the database for a specific investment using the
  # ID provided in the web link, making it available for other actions.
  #
  def load_application
    # Finds the specific record or stops the process if not found.
    @application = Application.find(params[:id])
  end

  # == load_form_dependencies
  #
  # @author Moisés Reis
  #
  # This gathers the list of portfolios and funds that the user is
  # allowed to use, specifically for filling out the selection menus.
  #
  def load_form_dependencies
    # Fetches all funds the user can access to populate the dropdowns.
    @fund_investments = FundInvestment.accessible_to(current_user)
                                      .includes(
                                        :portfolio,
                                        :investment_fund
                                      )
  end

  # == authorize_application
  #
  # @author Moisés Reis
  #
  # This double-checks that the current user has the authority to
  # modify the investment based on the portfolio it belongs to.
  #
  def authorize_application
    fund_investment = @application.fund_investment

    # Confirms the user has management rights over this specific portfolio.
    authorize! :manage, fund_investment.portfolio
  end

  # == application_params
  #
  # @author Moisés Reis
  #
  # This filters the information coming from the web browser to
  # ensure only the correct and safe fields are allowed into the app.
  #
  def application_params
    params.require(:application).permit(
      :portfolio_id,
      :investment_fund_id,
      :fund_investment_id,
      :request_date,
      :financial_value,
      :number_of_quotas,
      :quota_value_at_application,
      :cotization_date,
      :liquidation_date
    )
  end

  # == parsed_date_params
  #
  # @author Moisés Reis
  #
  # This takes dates entered in the Brazilian format (day/month/year)
  # and converts them into a format the database can understand.
  #
  def parsed_date_params
    date_fields = %i[request_date cotization_date liquidation_date]
    raw = params.require(:application)

    # Loops through each date field to translate the format correctly.
    date_fields.each_with_object({}) do |field, hash|
      raw_value = raw[field].presence
      next unless raw_value

      parsed = parse_br_date(raw_value)
      hash[field] = parsed if parsed
    end
  end

  # == parse_br_date
  #
  # @author Moisés Reis
  #
  # This helper logic identifies the standard Brazilian date pattern
  # and rearranges the numbers into a valid calendar date format.
  #
  def parse_br_date(value)
    # Returns the value as-is if it doesn't match the expected pattern.
    return value unless value.match?(%r{\A\d{2}/\d{2}/\d{4}\z})

    day, month, year = value.split("/")

    # Rearranges the day, month, and year into the database's preferred order.
    Date.new(year.to_i, month.to_i, day.to_i).iso8601
  rescue ArgumentError
    nil
  end

  # == update_fund_investment_after_create
  #
  # @author Moisés Reis
  #
  # This adds the value and shares of a new investment to the
  # main fund record, ensuring the total balance grows correctly.
  #
  def update_fund_investment_after_create(fund_investment)
    fund_investment.update_columns(
      total_quotas_held:    (fund_investment.total_quotas_held  || 0) + (@application.number_of_quotas || 0),
      total_invested_value: (fund_investment.total_invested_value || 0) + (@application.financial_value  || 0)
    )
  end

  def update_fund_investment_before_destroy(fund_investment)
    new_value  = [ (fund_investment.total_invested_value || 0) - (@application.financial_value    || 0), 0 ].max
    new_quotas = [ (fund_investment.total_quotas_held    || 0) - (@application.number_of_quotas  || 0), 0 ].max

    fund_investment.update_columns(
      total_invested_value: new_value,
      total_quotas_held:    new_quotas
    )
  end

  # == prepare_application_metrics
  #
  # @author Moisés Reis
  #
  # This calculates percentages, time delays, and consistency flags
  # so the user can see helpful insights on the investment details page.
  #
  def prepare_application_metrics
    # Calculates how much of this investment has already been assigned for withdrawal.
    allocated_quotas = @application.redemption_allocations.sum(:quotas_used) || 0

    # Works out the percentage of the investment that is currently allocated.
    @allocation_percentage =
      if @application.number_of_quotas.to_f.positive?
        (allocated_quotas.to_f / @application.number_of_quotas.to_f) * 100
      else
        0
      end

    # Determines how many days passed between the request and the final payment.
    @processing_days =
      if @application.request_date && @application.liquidation_date
        (@application.liquidation_date - @application.request_date).to_i
      end

    @calculated_quota_value = @application.calculated_quota_value
    @stored_quota_value = @application.quota_value_at_application

    # Checks if the share price saved matches the official price within a tiny margin.
    @is_quota_consistent =
      @calculated_quota_value &&
      @stored_quota_value &&
      (@calculated_quota_value - @stored_quota_value).abs <= 0.01

    # Ensures that dates follow a logical order in time.
    @cotization_valid =
      !@application.cotization_date ||
      !@application.request_date ||
      @application.cotization_date >= @application.request_date

    # Verifies that payment didn't happen before the shares were priced.
    @liquidation_valid =
      !@application.liquidation_date ||
      !@application.cotization_date ||
      @application.liquidation_date >= @application.cotization_date

    # Checks if the money values entered are valid positive numbers.
    @positive_values =
      @application.financial_value.to_f.positive? &&
      (@application.number_of_quotas.nil? || @application.number_of_quotas.to_f.positive?)

    # Assigns a visual status color based on whether the data is consistent.
    @quota_consistency_status =
      if @is_quota_consistent
        :success
      elsif @calculated_quota_value.present?
        :alert
      else
        :default
      end
  end
end
