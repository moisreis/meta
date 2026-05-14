# Provides user-related service objects and business operations.
#
# This namespace groups service classes responsible for orchestrating
# user-related workflows, validation handling, and dashboard aggregation logic.
#
# @author Moisés Reis

module Users

  # Builds the complete user detail presentation payload.
  #
  # This service aggregates portfolio metrics, financial summaries,
  # authentication metadata, and recent activity into a single structured
  # result object used by user detail and dashboard interfaces.
  class ShowService

    # ==========================================================================
    # RESULT OBJECTS
    # ==========================================================================

    # Immutable service result object returned by {.call}.
    #
    # @!attribute [r] user
    #   @return [User] User entity associated with the dashboard payload.
    #
    # @!attribute [r] portfolios
    #   @return [ActiveRecord::Relation<Portfolio>] Aggregated user portfolios.
    #
    # @!attribute [r] portfolios_count
    #   @return [Integer] Total number of associated portfolios.
    #
    # @!attribute [r] total_invested
    #   @return [BigDecimal] Total invested value across all portfolios.
    #
    # @!attribute [r] total_balance
    #   @return [BigDecimal] Total balance across all checking accounts.
    #
    # @!attribute [r] portfolios_for_compliance
    #   @return [ActiveRecord::Relation<Portfolio>] Portfolios with eager-loaded
    #     allocation data for compliance analysis.
    #
    # @!attribute [r] recent_applications
    #   @return [ActiveRecord::Relation<Application>] Recent investment
    #     applications associated with the user.
    #
    # @!attribute [r] recent_redemptions
    #   @return [ActiveRecord::Relation<Redemption>] Recent redemption requests
    #     associated with the user.
    #
    # @!attribute [r] last_sign_in_at
    #   @return [Time, nil] Timestamp of the user's last successful login.
    #
    # @!attribute [r] created_at
    #   @return [Time] Timestamp when the user account was created.
    #
    # @!attribute [r] sign_in_count
    #   @return [Integer] Total successful authentication count.
    Result = Struct.new(
      :user,
      :portfolios,
      :portfolios_count,
      :total_invested,
      :total_balance,
      :portfolios_for_compliance,
      :recent_applications,
      :recent_redemptions,
      :last_sign_in_at,
      :created_at,
      :sign_in_count,
      keyword_init: true
    )

    private_class_method :new

    # ==========================================================================
    # PUBLIC CLASS METHODS
    # ==========================================================================

    class << self

      # Executes the user detail aggregation workflow.
      #
      # @param user [User] User whose dashboard and detail data will be loaded.
      # @return [Result] Structured dashboard and detail presentation payload.
      def call(user)
        new(user: user).send(:call)
      end
    end

    # ==========================================================================
    # INITIALIZATION
    # ==========================================================================

    # Initializes the service object.
    #
    # @param user [User] User whose dashboard and detail data will be loaded.
    def initialize(user:)
      @user = user
    end

    # ==========================================================================
    # PRIVATE METHODS
    # ==========================================================================

    # Builds the aggregated user detail payload.
    #
    # The workflow aggregates:
    # - portfolio summaries
    # - investment totals
    # - account balances
    # - compliance allocation data
    # - recent investment activity
    # - authentication metadata
    #
    # @return [Result] Structured dashboard and detail presentation payload.
    def call
      portfolios = Users::PortfoliosQuery.call(@user)

      portfolios_count = portfolios.length
      total_invested   = portfolios.sum(&:total_invested_value)

      Result.new(
        user:                      @user,
        portfolios:                portfolios,
        portfolios_count:          portfolios_count,
        total_invested:            total_invested,
        total_balance:             Users::TotalBalanceQuery.call(@user),
        portfolios_for_compliance: Users::PortfoliosWithAllocationsQuery.call(@user),
        recent_applications:       Users::RecentApplicationsQuery.call(@user),
        recent_redemptions:        Users::RecentRedemptionsQuery.call(@user),
        last_sign_in_at:           @user.last_sign_in_at,
        created_at:                @user.created_at,
        sign_in_count:             @user.sign_in_count
      )
    end
  end
end
