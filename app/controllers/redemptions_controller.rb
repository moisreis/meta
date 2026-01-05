# === redemptions_controller
#
# @author Moisés Reis
# @added 11/28/2025
# @package *Meta*
# @description This controller manages all client requests related to withdrawing money (redemptions) from their **FundInvestment** accounts.
#              It handles listing, creation, viewing, and deletion of redemption records,
#              while enforcing business rules, especially the FIFO quota allocation method.
# @category *Controller*
#
# Usage:: - *[What]* It processes all HTTP requests for redemption transactions, serving the necessary views and APIs.
#         - *[How]* It uses strong parameters, model scopes, Ransack for filtering,
#           and ActiveRecord transactions to ensure data integrity during creation and destruction.
#         - *[Why]* It provides the secured, authenticated interface necessary for clients or administrators
#           to manage investment withdrawals correctly and safely, adhering to allocation logic.
#
class RedemptionsController < ApplicationController

  include PdfExportable

  # Explanation:: This is a security measure that ensures the user is logged
  #               into the application before they can execute any action within this controller.
  #               Access is strictly restricted to authenticated users.
  before_action :authenticate_user!

  # Explanation:: This method ensures that the redemption record specified by `params[:id]` is
  #               loaded into the `@redemption` instance variable before certain actions are executed.
  #               This prevents having to repeat the `Redemption.find(params[:id])` call inside `show`, `update`, and `destroy`.
  before_action :load_redemption, only: [
    :show,
    :update,
    :destroy
  ]

  # Explanation:: This method checks if the current logged-in user has the necessary permissions to manage the redemption being accessed.
  #               It uses the **CanCan** authorization system to protect the records from unauthorized viewing or manipulation.
  before_action :authorize_redemption, only: [
    :show,
    :update,
    :destroy
  ]

  # == index
  #
  # @author Moisés Reis
  # @category *Actions*
  #
  # Category:: This action retrieves and displays a paginated list of all redemption records the current user is authorized to view.
  #            It supports searching, filtering, and sorting via the Ransack gem.
  #
  # Attributes:: - *@q* @Ransack::Search - holds the search object for the collection, enabling complex filtering.
  #              - *@redemptions* @ActiveRecord::Relation - contains the final, paginated, and sorted list of redemption records to be displayed.
  #
  def index

    # Explanation:: This retrieves the IDs of all **FundInvestment** records that the current user has access to.
    #               This ensures the user can only see redemptions related to their own investments.
    fund_investment_ids = FundInvestment.accessible_to(current_user).select(:id)

    # Explanation:: This establishes the initial query scope by filtering redemptions linked to the accessible fund investments.
    #               It eagerly loads related data (portfolio, investment fund) to prevent N+1 query issues during rendering.
    base_scope = Redemption.where(fund_investment_id: fund_investment_ids)
                           .includes(
                             fund_investment: [
                               :portfolio,
                               :investment_fund
                             ],
                             )

    # Explanation:: This initializes the Ransack search object using the base scope and
    #               any filtering parameters passed in the `params[:q]` hash.
    #               This allows for dynamic searching on the records.
    @q = base_scope.ransack(params[:q])

    # Explanation:: This executes the search query defined by Ransack, ensuring that only distinct results are returned.
    #               The result is assigned to the `filtered` variable for further processing.
    filtered = @q.result(distinct: true)

    # Explanation:: This determines the column by which the records should be sorted,
    #               defaulting to `request_date` if no sort parameter is provided.
    #               It reads the sort parameter from the request.
    sort = params[:sort].presence || "request_date"

    # Explanation:: This determines the sort direction (ascending or descending),
    #               defaulting to `desc` (descending) if no direction parameter is provided.
    #               It reads the direction parameter from the request.
    direction = params[:direction].presence || "desc"

    # Explanation:: This variable stores the total number of records found in the database.
    #               It allows the user to see exactly how many items exist in the list.
    @total_items = Redemption.count

    # Explanation:: This applies the determined sort column and direction to the filtered set of redemptions.
    #               The result is assigned to the `sorted` variable.
    sorted = filtered.order("#{sort} #{direction}")

    # Explanation:: This applies pagination to the sorted result, showing a maximum of 20 records per page.
    #               The final result is assigned to the `@redemptions` instance variable for use in the view.
    @redemptions = sorted.page(params[:page]).per(14)

    respond_to do |format|
      format.html
    end
  end

  # == show
  #
  # @author Moisés Reis
  # @category *Actions*
  #
  # Category:: This action retrieves the details of a single redemption record and returns them as a JSON response.
  #            It is typically used by API calls to fetch data for display.
  #
  # Attributes:: - *@redemption* @Redemption - the specific record loaded by the `before_action`.
  #
  def show
  end

  # == new
  #
  # @author Moisés Reis
  # @category *Actions*
  #
  # Category:: This action initializes a new, unsaved **Redemption** object for the creation form.
  #            It also retrieves the list of possible investment funds the user can redeem from.
  #
  # Attributes:: - *@redemption* @Redemption - a new, unsaved instance of the **Redemption** model.
  #              - *@fund_investments* @ActiveRecord::Relation - a collection of **FundInvestment** records accessible to the current user.
  #
  def new

    # Explanation:: This creates a blank **Redemption** object, which is required by the form builder to populate the creation form.
    #               It prepares the object for initial data entry.
    @redemption = Redemption.new

    # Explanation:: This retrieves all the **FundInvestment** records that the current user is authorized to interact with.
    #               This collection populates the dropdown menu in the form, ensuring the user only selects valid investments.
    @fund_investments = FundInvestment.accessible_to(current_user)
  end

  # == create
  #
  # @author Moisés Reis
  # @category *Actions*
  #
  # Category:: This action processes the submission of the redemption creation form, attempts to save the record,
  #            and executes the FIFO quota allocation logic.
  #            It ensures that all database operations are wrapped in a transaction for atomicity.
  #
  # Attributes:: - *@redemption* @Redemption - the new redemption record, initialized with user parameters.
  #
  def create

    # Explanation:: This initializes a new **Redemption** object using the parameters submitted
    #               by the user through the `redemption_params` private method.
    #               The object is not yet saved to the database.
    @redemption = Redemption.new(redemption_params)

    # Explanation:: This retrieves the **FundInvestment** record associated with the new redemption,
    #               necessary for authorization and quota checks.
    #               It establishes the context for the transaction.
    fund_investment = @redemption.fund_investment

    # Explanation:: This performs an authorization check using **CanCan** to ensure the user is allowed to create a redemption linked to the specified investment.
    #               If authorization fails, an exception is raised.
    authorize! :create, @redemption, fund_investment

    # Explanation:: This checks if the requested number of redeemed quotas exceeds the total available quotas in the fund investment.
    #               If there are insufficient quotas, the method immediately stops and returns a JSON error response.
    unless @redemption.redeemed_quotas <= (fund_investment.total_quotas_held || 0)
      return render json: {
        status: 'Error',
        message: 'Insufficient quotas available for this redemption.'
      }, status: :unprocessable_entity
    end

    # Explanation:: This block initiates an ActiveRecord database transaction.
    #               All enclosed database operations (save, create, update) must succeed, or the entire block is rolled back.
    #               This guarantees the integrity of the data if any part of the creation or allocation process fails.
    ActiveRecord::Base.transaction do
      @redemption.save!
      allocate_quotas_fifo(fund_investment, @redemption.redeemed_quotas)
      update_fund_investment_after_redemption(fund_investment)
    end

    # Explanation:: If the transaction is successful, this renders a success JSON response,
    #               including the attributes of the newly created redemption record.
    #               It uses the HTTP status `:created` (201).
    render json: {
      status: 'Success',
      data: RedemptionSerializer.new(@redemption).serializable_hash[:data][:attributes]
    }, status: :created

    # Explanation:: This block catches any **ActiveRecord::RecordInvalid** exceptions that occur during the transaction (e.g., validation failures).
    #               It extracts the error messages and returns a JSON error response with the HTTP status `:unprocessable_entity` (422).
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      status: 'Error',
      errors: e.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  # == update
  #
  # @author Moisés Reis
  # @category *Actions*
  #
  # Category:: This action prevents the user from modifying an existing redemption record.
  #            Redemption records are treated as immutable financial events to maintain a complete audit trail.
  #
  def update
    render json: {
      status: 'Error',
      message: 'Redemption records cannot be updated'
    }, status: :method_not_allowed
  end

  # == destroy
  #
  # @author Moisés Reis
  # @category *Actions*
  #
  # Category:: This action handles the permanent deletion of a redemption record.
  #            Crucially, it first reverts the quotas and financial values back to the original applications before deletion.
  #
  # Attributes:: - *@redemption* @Redemption - the record to be deleted.
  #
  def destroy

    # Explanation:: This retrieves the associated **FundInvestment** record,
    #               which is necessary for reverting the quota balances.
    #               It provides the context for updating the investment portfolio.
    fund_investment = @redemption.fund_investment

    # Explanation:: This initiates a database transaction to ensure that the
    #               quota reversion and the redemption deletion happen together or not at all.
    #               If any step fails, the entire process is rolled back.
    ActiveRecord::Base.transaction do
      revert_quotas_on_destroy(fund_investment)
      @redemption.destroy!
    end

    # Explanation:: If the deletion and quota reversion are successful, this renders a
    #               JSON response confirming the successful deletion.
    #               It uses the HTTP status `:ok` (200).
    render json: {
      status: 'Success',
      message: 'Redemption deleted successfully'
    }, status: :ok

    # Explanation:: This handles validation errors during the deletion process
    #               (though less common here) and returns a JSON error response.
    #               This acts as a safeguard against data integrity issues.
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      status: 'Error',
      message: 'Failed to delete redemption',
      errors: e.record.errors.full_messages
    }, status: :unprocessable_entity

    # Explanation:: This handles cases where the redemption record specified by the ID does not exist in the database.
    #               It returns a JSON error with the HTTP status `:not_found` (404).
  rescue ActiveRecord::RecordNotFound => e
    render json: {
      status: 'Error',
      message: "Redemption not found: #{e.message}"
    }, status: :not_found

    # Explanation:: This handles access denial exceptions raised by the **CanCan** authorization gem.
    #               It returns a JSON error with the HTTP status `:forbidden` (403).
  rescue CanCan::AccessDenied => e
    render json: {
      status: 'Error',
      message: e.message
    }, status: :forbidden
  end

  private

  # == load_redemption
  #
  # @author Moisés Reis
  # @category *Method*
  #
  # Category:: This private method finds a **Redemption** record by its
  #            ID and assigns it to the `@redemption` instance variable.
  #            It serves as a helper method for the `before_action` callback.
  #
  def load_redemption
    @redemption = Redemption.find(params[:id])
  end

  # == authorize_redemption
  #
  # @author Moisés Reis
  # @category *Method*
  #
  # Category:: This private method enforces access control for the `show`, `update`, and `destroy` actions.
  #            Authorization is based on the user's rights to manage the parent **Portfolio** of the associated **FundInvestment**.
  #
  def authorize_redemption

    # Explanation:: This retrieves the linked **FundInvestment** record from the redemption object.
    #               It establishes the path to the higher-level **Portfolio** for authorization checks.
    fund_investment = @redemption.fund_investment

    # Explanation:: This uses **CanCan** to authorize the user's access to the parent portfolio,
    #               but only if the action being performed is `show`, `update`, or `destroy`.
    #               If the user cannot manage the portfolio, they cannot manage the redemption.
    authorize! :manage, fund_investment.portfolio if %w[show update destroy].include?(action_name)
  end

  # == redemption_params
  #
  # @author Moisés Reis
  # @category *Method*
  #
  # Category:: This private method defines and sanitizes the parameters allowed to be passed from the client to create or update a redemption.
  #            It prevents mass assignment vulnerabilities by explicitly permitting only safe attributes.
  #
  # Attributes:: - *@return* @Hash - returns a hash containing only the whitelisted parameters for redemption creation.
  #
  def redemption_params
    params.require(:redemption).permit(
      :fund_investment_id,
      :request_date,
      :redeemed_liquid_value,
      :redeemed_quotas,
      :redemption_yield,
      :redemption_type,
      :cotization_date,
      :liquidation_date
    )
  end

  # == update_fund_investment_after_redemption
  #
  # @author Moisés Reis
  # @category *Method*
  #
  # Category:: This private method recalculates and updates the total quotas held and total invested
  #            value of the parent **FundInvestment** after a successful redemption.
  #            It deducts the redeemed amounts from the investment balances.
  #
  # Attributes:: - *fund_investment* @FundInvestment - the investment record to be updated.
  #
  def update_fund_investment_after_redemption(fund_investment)

    # Explanation:: This retrieves the current total number of quotas held in the fund investment,
    #               defaulting to zero if the value is nil.
    #               It establishes the starting balance for the calculation.
    current_quotas = fund_investment.total_quotas_held || BigDecimal('0')

    # Explanation:: This retrieves the current total invested value in the fund, defaulting to zero if the value is nil.
    #               It establishes the starting financial balance.
    current_value = fund_investment.total_invested_value || BigDecimal('0')

    # Explanation:: This retrieves the number of quotas redeemed in the current transaction, defaulting to zero if the value is nil.
    #               It determines the amount to be deducted.
    redeemed_quotas = @redemption.redeemed_quotas || BigDecimal('0')

    # Explanation:: This retrieves the final liquid value redeemed in the current transaction, defaulting to zero if the value is nil.
    #               It determines the financial value to be deducted.
    redeemed_value = @redemption.redeemed_liquid_value || BigDecimal('0')

    # Explanation:: This calculates the new total invested value by subtracting the redeemed liquid value
    #               from the current invested value, ensuring the result is never negative.
    #               This updates the portfolio's overall value.
    new_total_value = [current_value - redeemed_value, BigDecimal('0')].max

    # Explanation:: This calculates the new total quotas held by subtracting the redeemed quotas
    #               from the current total quotas, ensuring the result is never negative.
    #               This updates the portfolio's quota count.
    new_total_quotas = [current_quotas - redeemed_quotas, BigDecimal('0')].max

    # Explanation:: This updates the **FundInvestment** record with the newly calculated totals for quotas and invested value.
    #               The `!` ensures an exception is raised if the update fails, triggering a transaction rollback.
    fund_investment.update!(
      total_quotas_held: new_total_quotas,
      total_invested_value: new_total_value
    )
  end

  # == revert_quotas_on_destroy
  #
  # @author Moisés Reis
  # @category *Method*
  #
  # Category:: This private method reverses the effects of a redemption when the record is destroyed.
  #            It restores the quotas and financial values back to the original
  #            **Application** records and the parent **FundInvestment**.
  #
  # Attributes:: - *fund_investment* @FundInvestment - the parent investment record whose balances need restoration.
  #
  def revert_quotas_on_destroy(fund_investment)

    # Explanation:: This retrieves the current total invested value from the fund investment record.
    #               This is the starting point before adding the reverted value back.
    current_value = fund_investment.total_invested_value || BigDecimal('0')

    # Explanation:: This retrieves the current total number of quotas held from the fund investment record.
    #               This is the starting point before adding the reverted quotas back.
    current_quotas = fund_investment.total_quotas_held || BigDecimal('0')

    # Explanation:: This calculates the total financial value to be reverted by summing up
    #               the quota value (at application time) for all quotas used in the redemption.
    #               This determines the amount to be restored to the `total_invested_value`.
    reverted_value = @redemption.redemption_allocations.sum do |allocation|
      allocation.quotas_used * allocation.application.quota_value_at_application
    end

    # Explanation:: This calculates the total number of quotas to be reverted by summing the `quotas_used`
    #               across all associated redemption allocations.
    #               This determines the quota amount to be restored.
    reverted_quotas = @redemption.redemption_allocations.sum(:quotas_used) || BigDecimal('0')

    # Explanation:: This iterates through each **RedemptionAllocation** record associated with the redemption being destroyed.
    #               The purpose is to restore the quotas to the specific applications they were redeemed from.
    @redemption.redemption_allocations.each do |allocation|

      # Explanation:: This retrieves the original **Application** record that the quotas were taken from.
      #               It is necessary to directly update the application's balances.
      application = allocation.application

      # Explanation:: This calculates the financial value corresponding to the quotas being restored,
      #               using the original quota value at the time of the application.
      #               It ensures the financial restoration is accurate to the original application.
      restored_financial_value = allocation.quotas_used * application.quota_value_at_application

      # Explanation:: This updates the original **Application** record by increasing
      #               its `number_of_quotas` and `financial_value` by the amounts that were redeemed.
      #               This effectively undoes the FIFO allocation and restores the application's status.
      application.update!(
        number_of_quotas: application.number_of_quotas + allocation.quotas_used,
        financial_value: application.financial_value + restored_financial_value
      )
    end

    # Explanation:: This updates the parent **FundInvestment** record by adding the
    #               total reverted value and quotas back to its current balances.
    #               This completes the full reversal of the redemption transaction.
    fund_investment.update!(
      total_invested_value: current_value + reverted_value,
      total_quotas_held: current_quotas + reverted_quotas
    )
  end

  # == allocate_quotas_fifo
  #
  # @author Moisés Reis
  # @category *Method*
  #
  # Category:: This private method implements the First-In, First-Out (FIFO)
  #            logic to allocate redeemed quotas against the oldest **Application** records.
  #            It creates new **RedemptionAllocation** records and reduces the balances of the original applications.
  #
  # Attributes:: - *fund_investment* @FundInvestment - the investment record containing the applications to redeem from.
  #              - *remaining_quotas* @decimal - the number of quotas that still need to be allocated for the current redemption.
  #
  def allocate_quotas_fifo(fund_investment, remaining_quotas)

    # Explanation:: This retrieves all **Application** records for the fund investment that still hold quotas, sorted by their cotization date.
    #               Sorting ensures that the oldest applications (First-In) are processed first (FIFO).
    applications = fund_investment.applications.where('number_of_quotas > 0').order(:cotization_date)

    # Explanation:: This iterates through the sorted applications, starting with the oldest ones.
    #               The process continues until all redeemed quotas have been allocated.
    applications.each do |app|

      # Explanation:: This breaks the loop if there are no more quotas left to allocate for the redemption.
      #               It stops unnecessary iteration once the target amount is reached.
      break if remaining_quotas <= 0

      # Explanation:: This calculates the number of quotas to take from the current application. It uses the smaller value between the quotas still available in the application and the quotas still needed for the redemption.
      #               This ensures the application's balance is not overdrawn.
      quotas_to_use = [app.number_of_quotas, remaining_quotas].min

      # Explanation:: This calculates the financial value corresponding to the quotas being used, based on the application's original quota value.
      #               This value is used to adjust the application's financial balance.
      value_to_use = quotas_to_use * app.quota_value_at_application

      # Explanation:: This creates a new **RedemptionAllocation** record to document how many quotas were taken from this specific application for the current redemption.
      #               This provides an auditable link between the redemption and the source applications.
      RedemptionAllocation.create!(
        redemption: @redemption,
        application: app,
        quotas_used: quotas_to_use,
        )

      # Explanation:: This calculates the remaining number of quotas left in the original application after the redemption takes place.
      #               This value updates the application record.
      new_quotas = app.number_of_quotas - quotas_to_use

      # Explanation:: This calculates the remaining financial value in the original application by subtracting the value corresponding to the redeemed quotas.
      #               This value updates the application record.
      new_value = app.financial_value - value_to_use

      # Explanation:: This updates the original **Application** record in the database with the new reduced quota count and financial value.
      #               `update_columns` is used for performance, as validations are skipped here since the integrity checks occur elsewhere.
      app.update_columns(
        number_of_quotas: new_quotas,
        financial_value: new_value,
        updated_at: Time.current
      )

      # Explanation:: This reduces the remaining number of quotas needed for the current redemption by the amount that was just allocated.
      #               This moves the process closer to the termination condition.
      remaining_quotas -= quotas_to_use
    end
  end

  # == pdf_export_title
  #
  # @author Moisés Reis
  # @category *Configuration*
  #
  # Configuration:: This method defines the main title displayed at the top of the PDF export.
  #                 It provides clear identification of the document type.
  #
  def pdf_export_title
    "Resgates"
  end

  # == pdf_export_subtitle
  #
  # @author Moisés Reis
  # @category *Configuration*
  #
  # Configuration:: This method defines the descriptive subtitle shown below the main title.
  #                 It clarifies the purpose and scope of the exported data.
  #
  def pdf_export_subtitle
    "Histórico de resgates realizados"
  end

  # == pdf_export_columns
  #
  # @author Moisés Reis
  # @category *Configuration*
  #
  # Configuration:: This method defines the structure of the PDF table, including column headers,
  #                 data extraction logic, and column widths. Each column specification includes
  #                 a header label, a key (symbol, string, or lambda), and an optional width.
  #
  # Attributes:: - *@return* @Array<Hash> - An array of column definitions for the PDF table.
  #
  def pdf_export_columns

    # Explanation:: This retrieves the helper proxy to access formatting methods.
    #               It allows the controller to use logic usually reserved for views.
    h = ActionController::Base.helpers

    [
      {
        header: "Data Solicitação",
        # Explanation:: This lambda extracts the request date from each redemption record.
        #               It formats the date using I18n localization or returns 'N/A' if nil.
        key: ->(redemption) do
          redemption.request_date ?
            I18n.l(redemption.request_date, format: :short) :
            'N/A'
        end,
        width: 85
      },
      {
        header: "Data Cotização",
        # Explanation:: This lambda extracts the cotization date from each redemption record.
        #               It formats the date using I18n localization or returns 'N/A' if nil.
        key: ->(redemption) do
          redemption.cotization_date ?
            I18n.l(redemption.cotization_date, format: :short) :
            'N/A'
        end,
        width: 85
      },
      {
        header: "Fundo",
        # Explanation:: This lambda navigates through the association chain to retrieve
        #               the fund name from the related InvestmentFund record.
        key: ->(redemption) do
          redemption.fund_investment.investment_fund.fund_name
        end,
        width: 150
      },
      {
        header: "Carteira",
        # Explanation:: This lambda retrieves the portfolio name from the parent
        #               FundInvestment record, showing which portfolio this redemption belongs to.
        key: ->(redemption) do
          redemption.fund_investment.portfolio.name
        end,
        width: 100
      },
      {
        header: "Tipo",
        # Explanation:: This lambda translates the redemption type from database values
        #               ('total', 'partial') to Portuguese display labels for clarity.
        key: ->(redemption) do
          case redemption.redemption_type
          when 'total'
            'Total'
          when 'partial'
            'Parcial'
          else
            redemption.redemption_type || 'N/A'
          end
        end,
        width: 60
      },
      {
        header: "Cotas Resgatadas",
        # Explanation:: This lambda formats the redeemed quotas using the helper proxy.
        #               It ensures consistent decimal precision across the document.
        key: ->(redemption) do
          h.number_with_precision(
            redemption.redeemed_quotas,
            precision: 2,
            separator: ",",
            delimiter: "."
          )
        end,
        width: 90
      },
      {
        header: "Valor Líquido",
        # Explanation:: This lambda formats the redeemed liquid value as Brazilian currency.
        #               It uses the helper proxy to ensure consistent currency formatting.
        key: ->(redemption) do
          h.number_to_currency(
            redemption.redeemed_liquid_value,
            unit: "R$ ",
            separator: ",",
            delimiter: "."
          )
        end,
        width: 90
      },
      {
        header: "Rendimento",
        # Explanation:: This lambda formats the redemption yield as currency if present.
        #               It returns 'N/A' for nil values to maintain data clarity.
        key: ->(redemption) do
          if redemption.redemption_yield
            h.number_to_currency(
              redemption.redemption_yield,
              unit: "R$ ",
              separator: ",",
              delimiter: "."
            )
          else
            'N/A'
          end
        end,
        width: 80
      }
    ]
  end

  # == pdf_export_data
  #
  # @author Moisés Reis
  # @category *Configuration*
  #
  # Configuration:: This method retrieves the collection of redemption records to be exported.
  #                 It applies the same scoping, filtering, and sorting logic as the index action
  #                 to ensure consistency between the displayed data and the exported data.
  #
  # Attributes:: - *@return* @ActiveRecord::Relation - The filtered and sorted collection of redemptions.
  #
  def pdf_export_data
    # Explanation:: This retrieves only the fund investment IDs that the current user
    #               has permission to access, establishing the authorization scope.
    fund_investment_ids = FundInvestment.accessible_to(current_user).select(:id)

    # Explanation:: This creates the base query scope by filtering redemptions linked
    #               to accessible fund investments and eagerly loading related associations.
    base_scope = Redemption.where(fund_investment_id: fund_investment_ids)
                           .includes(
                             fund_investment: [
                               :portfolio,
                               :investment_fund
                             ]
                           )

    # Explanation:: This initializes the Ransack search object with any filter
    #               parameters passed in the URL, preserving the user's current filters.
    @q = base_scope.ransack(params[:q])

    # Explanation:: This determines the sorting column and direction, defaulting to
    #               request_date descending to show most recent redemptions first.
    sort = params[:sort].presence || "request_date"
    direction = params[:direction].presence || "desc"

    # Explanation:: This executes the search query and applies the sorting order,
    #               returning the final collection ready for PDF generation.
    @q.result(distinct: true).order("#{sort} #{direction}")
  end

  # == pdf_export_metadata
  #
  # @author Moisés Reis
  # @category *Utility*
  #
  # Utility:: This method compiles the summary information for the PDF report.
  #            It calculates aggregate statistics and formats them for display
  #            in the metadata section of the exported document.
  #
  # Attributes:: - *pdf_export_data* - The collection of records used to calculate the total.
  #
  def pdf_export_metadata
    # Explanation:: This retrieves the helper proxy to access formatting methods.
    #               It allows the controller to use logic usually reserved for views.
    h = ActionController::Base.helpers

    # Explanation:: This retrieves the complete data collection to calculate
    #               aggregate statistics like totals and counts.
    data = pdf_export_data

    {
      'Usuário' => current_user.full_name,
      'E-mail' => current_user.email,
      # Explanation:: This counts the total number of redemption records in the export.
      'Total de resgates' => data.size.to_s,
      # Explanation:: This calculates and formats the sum of all redeemed liquid values
      #               using the helper proxy for consistent currency formatting.
      'Valor total resgatado' => h.number_to_currency(
        data.sum(:redeemed_liquid_value),
        unit: "R$ ",
        separator: ",",
        delimiter: "."
      ),
      # Explanation:: This calculates and formats the sum of all redeemed quotas
      #               using the helper proxy for consistent number formatting.
      'Cotas totais resgatadas' => h.number_with_precision(
        data.sum(:redeemed_quotas),
        precision: 2,
        separator: ",",
        delimiter: "."
      )
    }
  end
end