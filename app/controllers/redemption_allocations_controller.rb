# === redemption_allocations_controller
#
# @author Moisés Reis
# @added 12/03/2025
# @package *Meta*
# @description This controller manages all client requests related to viewing and managing
#              the allocation records that link redemptions to their source applications.
#              It handles listing, viewing, creation, and deletion of allocation records,
#              enforcing business rules and maintaining FIFO integrity.
# @category *Controller*
#
# Usage:: - *[What]* It processes all HTTP requests for redemption allocation transactions,
#           serving the necessary views and APIs for tracking quota usage.
#         - *[How]* It uses strong parameters, model scopes, Ransack for filtering,
#           and ActiveRecord transactions to ensure data integrity during creation and destruction.
#         - *[Why]* It provides the secured interface necessary for administrators to view,
#           audit, and manage the detailed allocation history between redemptions and applications.
#
class RedemptionAllocationsController < ApplicationController

  # Explanation:: This is a security measure that ensures the user is logged into the application
  #               before they can execute any action within this controller.
  before_action :authenticate_user!

  # Explanation:: This method ensures that the allocation record specified by `params[:id]` is
  #               loaded into the `@redemption_allocation` instance variable before certain actions are executed.
  before_action :load_redemption_allocation, only: [
    :show,
    :destroy
  ]

  # Explanation:: This method checks if the current logged-in user has the necessary permissions
  #               to manage the allocation being accessed, using the **CanCan** authorization system.
  before_action :authorize_redemption_allocation, only: [
    :show,
    :destroy
  ]

  # Explanation:: This method pre-fetches the necessary data for creating new allocations,
  #               including accessible redemptions and applications.
  before_action :load_form_dependencies, only: [
    :new,
    :create
  ]

  # == index
  #
  # @author Moisés Reis
  # @category *Actions*
  #
  # Category:: This action retrieves and displays a paginated list of all redemption allocation
  #            records the current user is authorized to view, with support for searching and filtering.
  #
  # Attributes:: - *@q* @Ransack::Search - holds the search object for the collection.
  #              - *@redemption_allocations* @ActiveRecord::Relation - contains the final paginated list.
  #
  def index

    # Explanation:: This retrieves the IDs of all **FundInvestment** records that the current user has access to,
    #               ensuring the user can only see allocations related to their own investments.
    fund_investment_ids = FundInvestment.accessible_to(current_user).select(:id)

    # Explanation:: This retrieves the IDs of redemptions linked to accessible fund investments,
    #               establishing the scope for allocation filtering.
    redemption_ids = Redemption.where(fund_investment_id: fund_investment_ids).select(:id)

    # Explanation:: This establishes the initial query scope by filtering allocations linked to
    #               accessible redemptions, eagerly loading related data to prevent N+1 queries.
    base_scope = RedemptionAllocation.where(redemption_id: redemption_ids)
                                     .includes(
                                       redemption: {
                                         fund_investment: [
                                           :portfolio,
                                           :investment_fund
                                         ]
                                       },
                                       application: {
                                         fund_investment: [
                                           :portfolio,
                                           :investment_fund
                                         ]
                                       }
                                     )

    # Explanation:: This initializes the Ransack search object using the base scope and
    #               any filtering parameters passed in the `params[:q]` hash.
    @q = base_scope.ransack(params[:q])

    # Explanation:: This executes the search query defined by Ransack, ensuring distinct results.
    filtered = @q.result(distinct: true)

    # Explanation:: This determines the column by which records should be sorted,
    #               defaulting to `created_at` if no sort parameter is provided.
    sort = params[:sort].presence || "created_at"

    # Explanation:: This determines the sort direction, defaulting to descending (newest first)
    #               if no direction parameter is provided.
    direction = params[:direction].presence || "desc"

    # Explanation:: This applies the determined sort column and direction to the filtered allocations.
    sorted = filtered.order("#{sort} #{direction}")

    # Explanation:: This applies pagination to the sorted result, showing 20 records per page.
    @redemption_allocations = sorted.page(params[:page]).per(20)

    respond_to do |format|
      format.html
      format.json {
        render json: {
          status: 'Success',
          data: RedemptionAllocationSerializer.new(@redemption_allocations).serializable_hash
        }
      }
    end
  end

  # == show
  #
  # @author Moisés Reis
  # @category *Actions*
  #
  # Category:: This action retrieves the details of a single redemption allocation record
  #            and returns them for display in the view or as a JSON response.
  #
  # Attributes:: - *@redemption_allocation* @RedemptionAllocation - the specific record loaded by the `before_action`.
  #
  def show
    respond_to do |format|
      format.html
      format.json {
        render json: {
          status: 'Success',
          data: RedemptionAllocationSerializer.new(@redemption_allocation).serializable_hash[:data][:attributes]
        }
      }
    end
  end

  # == new
  #
  # @author Moisés Reis
  # @category *Actions*
  #
  # Category:: This action initializes a new, unsaved **RedemptionAllocation** object for the creation form.
  #            It also retrieves lists of possible redemptions and applications.
  #
  # Attributes:: - *@redemption_allocation* @RedemptionAllocation - a new, unsaved instance.
  #              - *@redemptions* @ActiveRecord::Relation - collection of accessible redemptions.
  #              - *@applications* @ActiveRecord::Relation - collection of accessible applications.
  #
  def new
    @redemption_allocation = RedemptionAllocation.new

    # Explanation:: This pre-populates the redemption if passed as a parameter,
    #               making it easier to create allocations in context.
    if params[:redemption_id].present?
      @redemption_allocation.redemption_id = params[:redemption_id]
    end

    # Explanation:: This pre-populates the application if passed as a parameter.
    if params[:application_id].present?
      @redemption_allocation.application_id = params[:application_id]
    end
  end

  # == create
  #
  # @author Moisés Reis
  # @category *Actions*
  #
  # Category:: This action processes the submission of the allocation creation form,
  #            validates the data, and saves the record with proper authorization checks.
  #
  # Attributes:: - *@redemption_allocation* @RedemptionAllocation - the new allocation record.
  #
  def create
    @redemption_allocation = RedemptionAllocation.new(redemption_allocation_params)

    # Explanation:: This retrieves the redemption and application records for authorization
    #               and validation purposes.
    redemption = @redemption_allocation.redemption
    application = @redemption_allocation.application

    # Explanation:: This performs authorization checks to ensure the user can manage both
    #               the redemption's and application's portfolios.
    authorize! :manage, redemption.fund_investment.portfolio if redemption
    authorize! :manage, application.fund_investment.portfolio if application

    # Explanation:: This initiates a database transaction to ensure the allocation save
    #               and any related updates succeed together or roll back completely.
    ActiveRecord::Base.transaction do
      @redemption_allocation.save!
      update_application_after_create(application)
    end

    respond_to do |format|
      format.html {
        redirect_to redemption_allocation_path(@redemption_allocation),
                    notice: 'Redemption allocation was successfully created.'
      }
      format.json {
        render json: {
          status: 'Success',
          data: RedemptionAllocationSerializer.new(@redemption_allocation).serializable_hash[:data][:attributes]
        }, status: :created
      }
    end

  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.html { render :new, status: :unprocessable_entity }
      format.json {
        render json: {
          status: 'Error',
          errors: e.record.errors.full_messages
        }, status: :unprocessable_entity
      }
    end

  rescue CanCan::AccessDenied => e
    respond_to do |format|
      format.html { redirect_to redemption_allocations_path, alert: e.message }
      format.json {
        render json: {
          status: 'Error',
          message: e.message
        }, status: :forbidden
      }
    end
  end

  # == destroy
  #
  # @author Moisés Reis
  # @category *Actions*
  #
  # Category:: This action handles the permanent deletion of a redemption allocation record.
  #            It first reverts the quotas back to the original application before deletion.
  #
  # Attributes:: - *@redemption_allocation* @RedemptionAllocation - the record to be deleted.
  #
  def destroy
    application = @redemption_allocation.application
    redemption = @redemption_allocation.redemption

    # Explanation:: This initiates a database transaction to ensure that the
    #               quota reversion and allocation deletion happen atomically.
    ActiveRecord::Base.transaction do
      revert_quotas_on_destroy(application)
      @redemption_allocation.destroy!
    end

    respond_to do |format|
      format.html {
        redirect_to redemption_path(redemption),
                    notice: 'Redemption allocation was successfully deleted.',
                    status: :see_other
      }
      format.json {
        render json: {
          status: 'Success',
          message: 'Redemption allocation deleted successfully'
        }, status: :ok
      }
    end

  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.html {
        redirect_to redemption_allocation_path(@redemption_allocation),
                    alert: 'Failed to delete redemption allocation'
      }
      format.json {
        render json: {
          status: 'Error',
          message: 'Failed to delete redemption allocation',
          errors: e.record.errors.full_messages
        }, status: :unprocessable_entity
      }
    end

  rescue ActiveRecord::RecordNotFound => e
    respond_to do |format|
      format.html { redirect_to redemption_allocations_path, alert: 'Redemption allocation not found' }
      format.json {
        render json: {
          status: 'Error',
          message: "Redemption allocation not found: #{e.message}"
        }, status: :not_found
      }
    end

  rescue CanCan::AccessDenied => e
    respond_to do |format|
      format.html { redirect_to redemption_allocations_path, alert: e.message }
      format.json {
        render json: {
          status: 'Error',
          message: e.message
        }, status: :forbidden
      }
    end
  end

  private

  # == load_redemption_allocation
  #
  # @author Moisés Reis
  # @category *Method*
  #
  # Category:: This private method finds a **RedemptionAllocation** record by its
  #            ID and assigns it to the `@redemption_allocation` instance variable.
  #
  def load_redemption_allocation
    @redemption_allocation = RedemptionAllocation.find(params[:id])
  end

  # == load_form_dependencies
  #
  # @author Moisés Reis
  # @category *Method*
  #
  # Category:: This private method pre-fetches redemptions and applications that
  #            the current user can access for populating form dropdowns.
  #
  def load_form_dependencies
    fund_investment_ids = FundInvestment.accessible_to(current_user).select(:id)

    @redemptions = Redemption.where(fund_investment_id: fund_investment_ids)
                             .includes(fund_investment: [:portfolio, :investment_fund])
                             .order(request_date: :desc)

    @applications = Application.where(fund_investment_id: fund_investment_ids)
                               .where('number_of_quotas > 0')
                               .includes(fund_investment: [:portfolio, :investment_fund])
                               .order(cotization_date: :asc)
  end

  # == authorize_redemption_allocation
  #
  # @author Moisés Reis
  # @category *Method*
  #
  # Category:: This private method enforces access control by checking if the user
  #            has permissions to manage the portfolios of both the redemption and application.
  #
  def authorize_redemption_allocation
    redemption = @redemption_allocation.redemption
    application = @redemption_allocation.application

    authorize! :manage, redemption.fund_investment.portfolio
    authorize! :manage, application.fund_investment.portfolio
  end

  # == redemption_allocation_params
  #
  # @author Moisés Reis
  # @category *Method*
  #
  # Category:: This private method defines and sanitizes the parameters allowed
  #            to be passed from the client, preventing mass assignment vulnerabilities.
  #
  def redemption_allocation_params
    params.require(:redemption_allocation).permit(
      :redemption_id,
      :application_id,
      :quotas_used
    )
  end

  # == update_application_after_create
  #
  # @author Moisés Reis
  # @category *Method*
  #
  # Category:: This private method updates the application's quota and financial value
  #            balances after a new allocation is created, deducting the allocated amounts.
  #
  # Attributes:: - *application* @Application - the application record to be updated.
  #
  def update_application_after_create(application)
    return unless application

    # Explanation:: This retrieves the current number of quotas in the application,
    #               defaulting to zero if the value is nil.
    current_quotas = application.number_of_quotas || BigDecimal('0')

    # Explanation:: This retrieves the current financial value in the application,
    #               defaulting to zero if the value is nil.
    current_value = application.financial_value || BigDecimal('0')

    # Explanation:: This retrieves the quota value at the time of the original application,
    #               necessary for calculating the financial deduction.
    quota_value = application.quota_value_at_application || BigDecimal('0')

    # Explanation:: This retrieves the number of quotas used in the allocation,
    #               defaulting to zero if the value is nil.
    quotas_used = @redemption_allocation.quotas_used || BigDecimal('0')

    # Explanation:: This calculates the financial value corresponding to the allocated quotas.
    value_to_deduct = quotas_used * quota_value

    # Explanation:: This calculates the new quota balance, ensuring it never goes below zero.
    new_quotas = [current_quotas - quotas_used, BigDecimal('0')].max

    # Explanation:: This calculates the new financial value balance, ensuring it never goes below zero.
    new_value = [current_value - value_to_deduct, BigDecimal('0')].max

    # Explanation:: This updates the application record with the new reduced balances.
    application.update!(
      number_of_quotas: new_quotas,
      financial_value: new_value
    )
  end

  # == revert_quotas_on_destroy
  #
  # @author Moisés Reis
  # @category *Method*
  #
  # Category:: This private method reverses the effects of an allocation when it is destroyed,
  #            restoring the quotas and financial values back to the original application.
  #
  # Attributes:: - *application* @Application - the application record whose balances need restoration.
  #
  def revert_quotas_on_destroy(application)
    return unless application

    # Explanation:: This retrieves the current number of quotas in the application.
    current_quotas = application.number_of_quotas || BigDecimal('0')

    # Explanation:: This retrieves the current financial value in the application.
    current_value = application.financial_value || BigDecimal('0')

    # Explanation:: This retrieves the quota value at the time of the original application.
    quota_value = application.quota_value_at_application || BigDecimal('0')

    # Explanation:: This retrieves the number of quotas that were allocated and need to be restored.
    quotas_to_restore = @redemption_allocation.quotas_used || BigDecimal('0')

    # Explanation:: This calculates the financial value corresponding to the quotas being restored.
    value_to_restore = quotas_to_restore * quota_value

    # Explanation:: This updates the application record by adding back the restored quotas and value.
    application.update!(
      number_of_quotas: current_quotas + quotas_to_restore,
      financial_value: current_value + value_to_restore
    )
  end
end