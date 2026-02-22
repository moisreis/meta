# === applications_controller
#
# @author Moisés Reis
# @added 11/24/2025
# @package *Meta*
# @description This controller manages all financial application records for investments.
#              It ensures the current user is authenticated and authorized to access
#              or modify investment data, working closely with the **FundInvestment**
#              and **Application** models.
# @category *Controller*
#
# Usage:: - *[What]* This code block controls the listing, viewing, creation,
#           and deletion of specific investment applications.
#         - *[How]* It uses **CanCan** to check permissions on the associated
#           **Portfolio** and executes complex database logic to ensure fund totals
#           are updated correctly whenever an application is added or removed.
#         - *[Why]* It centralizes all application-specific actions, protecting
#           sensitive financial data and maintaining data integrity of the overall fund totals.
#
# Attributes:: - *@application* @object - The specific application being viewed, edited, or destroyed.
#              - *@applications* @collection - The filtered and paginated list of applications for the index view.
#
class ApplicationsController < ApplicationController

  # Explanation:: This command confirms that a user is successfully logged into
  #               the system before allowing access to any actions within this controller.
  before_action :authenticate_user!

  # Explanation:: This runs before viewing, editing, updating, or destroying an application.
  #               It finds the specific record from the database using the ID provided in the web address.
  before_action :load_application, only: [
    :show,
    :edit,
    :update,
    :destroy
  ]

  # Explanation:: This runs immediately after loading the application. It checks user
  #               permissions using **CanCan** to ensure the user is authorized to
  #               manage the portfolio associated with this application.
  before_action :authorize_application, only: [
    :show,
    :edit,
    :update,
    :destroy
  ]

  # Explanation:: This runs before showing the new or edit forms. It pre-fetches the
  #               necessary data, such as a list of available **FundInvestment**
  #               records, to populate dropdown menus on the form.
  before_action :load_form_dependencies, only: [
    :new,
    :edit,
    :create
  ]

  # == index
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action retrieves all investment applications that the
  #        currently logged-in user is permitted to view. It then applies
  #        any sorting and filtering requests before displaying the results.
  #
  # Attributes:: - *params[:q]* - Search parameters used to filter the applications list.
  #             - *@applications* - The final list of applications prepared for the view.
  #
  def index

    # Explanation:: This line finds the unique identifiers of all investment funds
    #               that the current user has access to, ensuring security.
    fund_investments_ids = FundInvestment.accessible_to(current_user).select(:id)

    # Explanation:: This defines the starting point for the application search. It finds
    #               applications linked to the accessible funds and loads their related
    #               portfolio and fund data efficiently.
    base_scope = Application.where(fund_investment_id: fund_investments_ids)
                            .includes(fund_investment: [
                              :portfolio,
                              :investment_fund
                            ])

    # Explanation:: This initializes the search object using the **Ransack** gem,
    #               applying any search criteria passed in the web address (`params[:q]`).
    @q = base_scope.ransack(params[:q])

    # Explanation:: This executes the search query defined by Ransack, returning a
    #               unique list of applications that match the criteria.
    filtered_applications = @q.result(distinct: true)

    # Explanation:: This variable stores the total number of records found in the database.
    #               It allows the user to see exactly how many items exist in the list.
    @total_items = Application.count

    # Explanation:: This checks the web address for a specific sort column, defaulting
    #               to sorting by the application's request date if none is specified.
    sort = params[:sort].presence || "request_date"

    # Explanation:: This checks the web address for a specific sort direction, defaulting
    #               to descending order (newest first) if none is specified.
    direction = params[:direction].presence || "desc"

    # Explanation:: This applies the determined sort column and direction to the
    #               filtered list of applications.
    sorted_applications = filtered_applications.order("#{sort} #{direction}")

    # Explanation:: This prepares the final data for the page, dividing the complete
    #               list into pages of 20 items to improve performance and readability.
    @applications = sorted_applications.page(params[:page]).per(14)

    respond_to do |format|
      format.html
    end
  end

  # == show
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action prepares the specific application record that was
  #        loaded earlier so that the view can display all its details to the user.
  #
  # Attributes:: - *@application* - The single application object found by the `load_application` filter.
  #
  def show
    prepare_application_metrics

    respond_to do |format|
      format.html
    end
  end

  # == new
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action creates a new, blank **Application** object. This
  #        empty object is used by the form to gather input from the user.
  #
  # Attributes:: - *@application* - A new, unsaved application instance.
  #
  def new
    @application = Application.new
  end

  # == edit
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action prepares the view to display the existing application
  #        data, allowing the user to make changes.
  #
  # Attributes:: - *@application* - The existing application object loaded by the `before_action` filter.
  #
  def edit
  end

  # == create
  #
  # @author Moisés Reis
  # @category *Create*
  #
  # Create:: This action attempts to save a new application record to the
  #          database. If successful, it updates the associated fund's totals
  #          and redirects the user to the new application's detail page.
  #
  # Attributes:: - *application_params* - The sanitized input data from the user form.
  #
  def create
    @application = Application.new(application_params.merge(parsed_date_params))

    fund_investment = @application.fund_investment
    authorize! :manage, fund_investment.portfolio

    # Calcula automaticamente cota e número de cotas
    if @application.cotization_date.present? && @application.financial_value.present?
      quota_value = fund_investment.investment_fund.quota_value_on(@application.cotization_date)

      if quota_value
        @application.quota_value_at_application = quota_value
        @application.number_of_quotas = BigDecimal(@application.financial_value.to_s) / quota_value
      else
        @application.errors.add(:cotization_date, "sem cota disponível para esta data")
        render :new, status: :unprocessable_entity and return
      end
    end

    ActiveRecord::Base.transaction do
      @application.save!
      update_fund_investment_after_create(fund_investment)
    end

    flash[:notice] = "Investimento criado com sucesso."
    redirect_to application_path(@application)

  rescue ActiveRecord::RecordInvalid => e
    render :new, status: :unprocessable_entity

  rescue CanCan::AccessDenied => e
    redirect_to fund_investments_path
  end

  # == update
  #
  # @author Moisés Reis
  # @category *Update*
  #
  # Update:: This method explicitly disables the direct update of application
  #          records. Any modification to an application must be performed
  #          through a defined business process, like deletion and recreation.
  #
  # Attributes:: - *@application* - The existing application object.
  #
  def update
    redirect_to application_path(@application), status: :method_not_allowed
  end

  # == destroy
  #
  # @author Moisés Reis
  # @category *Delete*
  #
  # Delete:: This action deletes the application record from the database.
  #          It first subtracts the application's value and quotas from the
  #          associated fund's totals within a secure database transaction.
  #
  # Attributes:: - *@application* - The existing application object to be destroyed.
  #
  def destroy
    fund_investment = @application.fund_investment

    # Explanation:: This initiates a database transaction to ensure the fund totals
    #               are updated before the application is deleted. Both actions must succeed
    #               or fail together.
    ActiveRecord::Base.transaction do
      update_fund_investment_before_destroy(fund_investment)
      @application.destroy!
    end

    flash[:notice] = "Investimento deletado com sucesso."

    # Explanation:: After successful deletion and update of fund totals, this redirects
    #               the user to the detail page of the fund investment itself.
    redirect_to fund_investment_path(fund_investment.id), status: :see_other

    # Explanation:: If any database integrity error occurs during the transaction,
    #               the user is redirected to the application's detail page with an error.
  rescue ActiveRecord::RecordInvalid
    redirect_to application_path(@application)
  end

  private

  # == load_application
  #
  # @author Moisés Reis
  # @category *Utility*
  #
  # Utility:: This private method finds a single application record in the
  #           database using the ID from the web request and stores it for
  #           use by other controller methods.
  #
  # Attributes:: - *params[:id]* - The identifier of the application record.
  #
  def load_application
    @application = Application.find(params[:id])
  end

  # == load_form_dependencies
  #
  # @author Moisés Reis
  # @category *Utility*
  #
  # Utility:: This private method pre-fetches all the **FundInvestment**
  #           records that the current user can access. This data is used to
  #           populate the dropdown choices in the `new` and `edit` forms.
  #
  # Attributes:: - *@fund_investments* - A collection of accessible fund investment objects.
  #
  def load_form_dependencies
    @fund_investments = FundInvestment.accessible_to(current_user)
                                      .includes(
                                        :portfolio,
                                        :investment_fund
                                      )
  end

  # == authorize_application
  #
  # @author Moisés Reis
  # @category *Security*
  #
  # Security:: This private method uses **CanCan** to verify that the
  #            current user possesses the necessary permissions to manage the
  #            **Portfolio** associated with the current application.
  #
  def authorize_application
    fund_investment = @application.fund_investment
    authorize! :manage, fund_investment.portfolio
  end

  # == application_params
  #
  # @author Moisés Reis
  # @category *Security*
  #
  # Security:: This private method sanitizes all incoming data from the
  #            application form. It ensures that only specifically permitted
  #            fields, like `financial_value` and `request_date`, can be saved.
  #
  # Attributes:: - *params* - The raw data hash received from the user form submission.
  #
  def application_params
    params.require(:application).permit(
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
  # @category *Utility*
  #
  # Utility:: Converts the three date fields from the Brazilian DD/MM/YYYY format
  #           submitted by the front-end date picker into ISO 8601 (YYYY-MM-DD)
  #           strings that Rails can reliably cast to Date objects.
  #           Returns only the fields that are actually present in the request,
  #           so it is safe to merge over application_params without clobbering
  #           unrelated attributes.
  #
  def parsed_date_params
    date_fields = %i[request_date cotization_date liquidation_date]
    raw = params.require(:application)

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
  # @category *Utility*
  #
  # Utility:: Parses a date string that may arrive in DD/MM/YYYY format (Brazilian locale)
  #           and returns an ISO 8601 string (YYYY-MM-DD).
  #           Falls back to returning nil so the model validator surfaces a
  #           human-readable error instead of raising an exception.
  #
  # Attributes:: - *value* @string - The raw date string from the request params.
  #
  def parse_br_date(value)
    return value unless value.match?(%r{\A\d{2}/\d{2}/\d{4}\z})

    day, month, year = value.split("/")
    Date.new(year.to_i, month.to_i, day.to_i).iso8601
  rescue ArgumentError
    nil
  end

  # == update_fund_investment_after_create
  #
  # @author Moisés Reis
  # @category *Business Logic*
  #
  # Business Logic:: This private method updates the totals of the associated
  #                  **FundInvestment**. It adds the quotas and financial value of the
  #                  newly created application to the fund's current running totals.
  #
  # Attributes:: - *fund_investment* - The specific fund investment object to be updated.
  #
  def update_fund_investment_after_create(fund_investment)

    # Explanation:: This retrieves the current total number of quotas held in the fund,
    #               defaulting to zero if the value is missing.
    current_quotas = fund_investment.total_quotas_held || BigDecimal('0')

    # Explanation:: This retrieves the current total monetary value invested in the fund,
    #               defaulting to zero if the value is missing.
    current_value = fund_investment.total_invested_value || BigDecimal('0')

    # Explanation:: This extracts the number of quotas from the newly created application,
    #               defaulting to zero if the value is missing.
    application_quotas = @application.number_of_quotas || BigDecimal('0')

    # Explanation:: This extracts the financial value from the newly created application,
    #               defaulting to zero if the value is missing.
    application_value = @application.financial_value || BigDecimal('0')

    # Explanation:: This performs the final database update, saving the new, increased
    #               totals for quotas and invested value back to the fund investment record.
    fund_investment.update!(
      total_quotas_held: current_quotas + application_quotas,
      total_invested_value: current_value + application_value
    )
  end

  # == update_fund_investment_before_destroy
  #
  # @author Moisés Reis
  # @category *Business Logic*
  #
  # Business Logic:: This private method updates the totals of the associated
  #                  **FundInvestment** just before the application is deleted. It
  #                  subtracts the application's quotas and value from the fund's totals.
  #
  # Attributes:: - *fund_investment* - The specific fund investment object to be updated.
  #
  def update_fund_investment_before_destroy(fund_investment)

    # Explanation:: This retrieves the current total monetary value invested in the fund,
    #               defaulting to zero if the value is missing.
    current_value = fund_investment.total_invested_value || BigDecimal('0')

    # Explanation:: This retrieves the current total number of quotas held in the fund,
    #               defaulting to zero if the value is missing.
    current_quotas = fund_investment.total_quotas_held || BigDecimal('0')

    # Explanation:: This extracts the financial value that is about to be deleted with
    #               the application, defaulting to zero if the value is missing.
    application_value = @application.financial_value || BigDecimal('0')

    # Explanation:: This extracts the quota amount that is about to be deleted with
    #               the application, defaulting to zero if the value is missing.
    application_quotas = @application.number_of_quotas || BigDecimal('0')

    # Explanation:: This calculates the new total invested value after subtraction,
    #               ensuring the total never drops below zero (non-negative constraint).
    new_total_value = [current_value - application_value, BigDecimal('0')].max

    # Explanation:: This calculates the new total number of quotas after subtraction,
    #               ensuring the total never drops below zero (non-negative constraint).
    new_total_quotas = [current_quotas - application_quotas, BigDecimal('0')].max

    # Explanation:: This performs the final database update, saving the new, reduced
    #               totals for value and quotas back to the fund investment record.
    fund_investment.update!(
      total_invested_value: new_total_value,
      total_quotas_held: new_total_quotas
    )
  end

  # == prepare_application_metrics
  #
  # @category *Presentation Logic*
  #
  # Explanation:: Computes derived, read-only metrics used by the show view.
  #               This keeps the template declarative and free of business math.
  #
  def prepare_application_metrics
    allocated_quotas = @application.redemption_allocations.sum(:quotas_used) || 0

    @allocation_percentage =
      if @application.number_of_quotas.to_f.positive?
        (allocated_quotas.to_f / @application.number_of_quotas.to_f) * 100
      else
        0
      end

    @processing_days =
      if @application.request_date && @application.liquidation_date
        (@application.liquidation_date - @application.request_date).to_i
      end

    @calculated_quota_value = @application.calculated_quota_value
    @stored_quota_value     = @application.quota_value_at_application

    @is_quota_consistent =
      @calculated_quota_value &&
      @stored_quota_value &&
      (@calculated_quota_value - @stored_quota_value).abs <= 0.01

    @cotization_valid =
      !@application.cotization_date ||
      !@application.request_date ||
      @application.cotization_date >= @application.request_date

    @liquidation_valid =
      !@application.liquidation_date ||
      !@application.cotization_date ||
      @application.liquidation_date >= @application.cotization_date

    @positive_values =
      @application.financial_value.to_f.positive? &&
      (@application.number_of_quotas.nil? || @application.number_of_quotas.to_f.positive?)

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