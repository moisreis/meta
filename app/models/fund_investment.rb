# Represents an investment fund allocation inside a portfolio.
#
# A FundInvestment tracks quota balances, invested capital,
# portfolio allocation percentage, historical applications,
# redemptions, and performance evolution for a specific
# investment fund within a portfolio.
#
# This model does NOT calculate fund quota prices directly.
# Quota valuation logic belongs to {InvestmentFund}.
#
# @author Moisés Reis

class FundInvestment < ApplicationRecord

  # =============================================================
  #                         ASSOCIATIONS
  # =============================================================

  belongs_to :portfolio
  belongs_to :investment_fund

  has_many :applications, dependent: :destroy
  has_many :redemptions, dependent: :destroy
  has_many :performance_histories, dependent: :destroy

  # =============================================================
  #                          ATTRIBUTES
  # =============================================================

  # --- VIRTUAL ATTRIBUTES --------------------------------------

  # @!attribute [rw] skip_allocation_validation
  #   @return [Boolean]
  #   Skips portfolio allocation validation during
  #   internal balance recalculations.
  attr_accessor :skip_allocation_validation

  # =============================================================
  #                           VALIDATIONS
  # =============================================================

  validates :portfolio_id, presence: true
  validates :investment_fund_id, presence: true

  validates :total_invested_value,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  validates :total_quotas_held,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  validates :percentage_allocation,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 100
            }

  validates :investment_fund_id,
            uniqueness: { scope: :portfolio_id }

  validate :portfolio_allocation_within_limits

  # =============================================================
  #                             SCOPES
  # =============================================================

  # --- STATUS SCOPES -------------------------------------------

  # Returns investments with active balances or quotas.
  #
  # @return [ActiveRecord::Relation<FundInvestment>]
  scope :active, lambda {
    where("total_quotas_held > 0 OR total_invested_value > 0")
  }

  # Returns investments that were active during a
  # specific time range.
  #
  # @param start_date [Date]
  #   Initial date of the analyzed period.
  #
  # @param end_date [Date]
  #   Final date of the analyzed period.
  #
  # @return [ActiveRecord::Relation<FundInvestment>]
  scope :active_during, lambda { |start_date, end_date|
    had_application_ids = Application
                            .where("cotization_date <= ?", end_date)
                            .select(:fund_investment_id)

    redeemed_during_or_after_ids = Redemption
                                    .where("cotization_date >= ?", start_date)
                                    .select(:fund_investment_id)

    where(id: had_application_ids)
      .where(
        "total_quotas_held > 0 OR id IN (#{redeemed_during_or_after_ids.to_sql})"
      )
  }

  # --- SORTING SCOPES ------------------------------------------

  # Returns investments ordered by descending
  # allocation percentage.
  #
  # @return [ActiveRecord::Relation<FundInvestment>]
  scope :by_allocation, lambda {
    order(percentage_allocation: :desc)
  }

  # --- AUTHORIZATION SCOPES ------------------------------------

  # Returns investments accessible to a specific user.
  #
  # Administrators receive unrestricted access while
  # regular users are filtered by ownership and
  # explicit portfolio permissions.
  #
  # @param user [User]
  #   User requesting access.
  #
  # @return [ActiveRecord::Relation<FundInvestment>]
  scope :accessible_to, lambda { |user|
    if user.admin?
      all
    else
      joins(:portfolio)
        .joins(
          "LEFT JOIN user_portfolio_permissions " \
          "ON user_portfolio_permissions.portfolio_id = portfolios.id"
        )
        .where(
          "portfolios.user_id = ? " \
          "OR user_portfolio_permissions.user_id = ?",
          user.id,
          user.id
        )
        .distinct
    end
  }

  # Returns investments readable by a specific user.
  #
  # @param user [User]
  #   User requesting visibility access.
  #
  # @return [ActiveRecord::Relation<FundInvestment>]
  scope :readable_by, lambda { |user|
    joins(:portfolio)
      .where(
        portfolios: {
          id: Portfolio.readable_by(user).select(:id)
        }
      )
      .distinct
  }

  # Returns investments owned by a specific user.
  #
  # @param user [User]
  #   Portfolio owner.
  #
  # @return [ActiveRecord::Relation<FundInvestment>]
  scope :owned_by, lambda { |user|
    joins(:portfolio)
      .where(portfolios: { user_id: user.id })
  }

  # Returns investments shared with a user through
  # explicit portfolio permissions.
  #
  # @param user [User]
  #   User with delegated access permissions.
  #
  # @return [ActiveRecord::Relation<FundInvestment>]
  scope :with_permissions_for, lambda { |user|
    joins(portfolio: :user_portfolio_permissions)
      .where(user_portfolio_permissions: { user_id: user.id })
      .where.not(portfolios: { user_id: user.id })
  }

  # =============================================================
  #                        BALANCE MANAGEMENT
  # =============================================================

  # Updates investment balances atomically.
  #
  # The operation executes inside a database lock to
  # prevent concurrent balance inconsistencies.
  #
  # @param quotas_delta [Numeric]
  #   Delta applied to held quotas.
  #
  # @param value_delta [Numeric]
  #   Delta applied to invested value.
  #
  # @return [void]
  #
  # @raise [ActiveRecord::RecordInvalid]
  #   Raised when persistence fails.
  def update_balances!(quotas_delta:, value_delta:)
    with_lock do
      self.skip_allocation_validation = true

      self.total_quotas_held =
        (total_quotas_held || 0) + quotas_delta

      self.total_invested_value =
        (total_invested_value || 0) + value_delta

      save!
    end
  end

  # =============================================================
  #                     HISTORICAL VALUATION
  # =============================================================

  # Reconstructs the market value of the investment
  # on a specific historical date.
  #
  # Historical balances are rebuilt from applications
  # and redemptions up to the requested date.
  #
  # @param date [Date]
  #   Historical reference date.
  #
  # @return [BigDecimal]
  #   Historical market value for the investment.
  def current_market_value_on(date)
    quota = investment_fund.quota_value_on(date)

    return BigDecimal("0") unless quota

    quotas =
      applications
        .where("cotization_date <= ?", date)
        .sum(:number_of_quotas) -
      redemptions
        .where("cotization_date <= ?", date)
        .sum(:redeemed_quotas)

    BigDecimal(quotas.to_s) * quota
  end

  # =============================================================
  #                    AGGREGATION & METRICS
  # =============================================================

  # --- INITIAL DATES -------------------------------------------

  # Returns the earliest application cotization date.
  #
  # @return [Date, nil]
  #   Initial investment date.
  def initial_date
    applications.minimum(:cotization_date)
  end

  # --- APPLICATION METRICS -------------------------------------

  # Returns the total application value performed
  # after the initial investment date.
  #
  # @return [BigDecimal]
  #   Aggregated application value for the period.
  def period_applications
    return BigDecimal("0") unless initial_date

    BigDecimal(
      applications
        .where("cotization_date > ?", initial_date)
        .sum(:financial_value)
        .to_s
    )
  end

  # =============================================================
  #                       RANSACK SUPPORT
  # =============================================================

  # --- SEARCHABLE ATTRIBUTES -----------------------------------

  # Defines the attributes allowed for Ransack filtering.
  #
  # @param auth_object [Object, nil]
  #   Authorization context provided by Ransack.
  #
  # @return [Array<String>]
  #   List of searchable attributes.
  def self.ransackable_attributes(auth_object = nil)
    %w[
      created_at
      id
      investment_fund_id
      percentage_allocation
      portfolio_id
      total_invested_value
      total_quotas_held
      updated_at
    ]
  end

  # --- SEARCHABLE ASSOCIATIONS ---------------------------------

  # Defines the associations allowed for Ransack joins.
  #
  # @param auth_object [Object, nil]
  #   Authorization context provided by Ransack.
  #
  # @return [Array<String>]
  #   List of searchable associations.
  def self.ransackable_associations(auth_object = nil)
    %w[
      applications
      investment_fund
      performance_histories
      portfolio
      redemptions
    ]
  end

  private

  # =============================================================
  #                     CUSTOM VALIDATIONS
  # =============================================================

  # Ensures portfolio allocation percentages do not
  # exceed the maximum portfolio allocation limit.
  #
  # @return [void]
  def portfolio_allocation_within_limits
    return if skip_allocation_validation
    return unless portfolio && percentage_allocation
    return unless total_portfolio_allocation > 100

    errors.add(
      :percentage_allocation,
      "Esta porcentagem excede o limite de alocação da carteira."
    )
  end

  # =============================================================
  #                     ALLOCATION HELPERS
  # =============================================================

  # --- TOTAL ALLOCATION -----------------------------------------

  # Returns the total allocation percentage considering
  # the current investment allocation and all existing
  # portfolio allocations.
  #
  # @return [BigDecimal]
  #   Total calculated portfolio allocation percentage.
  def total_portfolio_allocation
    existing_allocation + percentage_allocation
  end

  # --- EXISTING ALLOCATION --------------------------------------

  # Returns the aggregated allocation percentage from
  # all other investments within the portfolio.
  #
  # The current investment record is excluded from the
  # calculation to support update operations correctly.
  #
  # @return [BigDecimal]
  #   Existing portfolio allocation percentage.
  def existing_allocation
    portfolio.fund_investments
            .where.not(id: id)
            .sum(:percentage_allocation)
  end
end