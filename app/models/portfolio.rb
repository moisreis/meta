# === portfolio.rb
#
# Description:: Represents a user's collection of investment funds and financial assets.
#               This model organizes holdings, tracks performance history, and manages
#               permissions for users to view or edit their investment portfolios.
#
# Usage:: - *What* - Acts as the primary organizational unit for a user's financial assets.
#         - *How* - It aggregates data from multiple investments to calculate total value,
#           gains, and performance metrics across different time periods.
#         - *Why* - Necessary to provide a centralized interface for tracking wealth
#           growth and managing multiple investment strategies within the system.
#
# Attributes:: - *@name* [String] - The name given by the user to identify this portfolio.
#              - *@annual_interest_rate* [Decimal] - The expected return rate target set for the portfolio.
#              - *@user_id* [Integer] - The ID of the owner who created this portfolio.
#
class Portfolio < ApplicationRecord

  belongs_to :user

  has_many :checking_accounts, dependent: :destroy
  has_many :fund_investments, dependent: :destroy
  has_many :investment_funds, through: :fund_investments
  has_many :user_portfolio_permissions, dependent: :destroy
  has_many :authorized_users, through: :user_portfolio_permissions, source: :user
  has_many :performance_histories, dependent: :destroy

  # Add alongside the existing has_many declarations:
  has_many :portfolio_normative_articles, dependent: :destroy
  has_many :normative_articles, through: :portfolio_normative_articles

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :annual_interest_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, presence: true

  accepts_nested_attributes_for :portfolio_normative_articles,
                                 allow_destroy: true,
                                 reject_if: :all_blank

  # =============================================================
  # Scopes
  # =============================================================

  scope :for_user, ->(user) {
    left_joins(:user_portfolio_permissions)
      .where("portfolios.user_id = ? OR user_portfolio_permissions.user_id = ?", user.id, user.id)
      .distinct
  }

  scope :readable_by, ->(user) {
    where(user_id: user.id)
      .or(joins(:user_portfolio_permissions).where(user_portfolio_permissions: { user_id: user.id }))
  }

  scope :manageable_by, ->(user) {
    where(user_id: user.id)
      .or(
        joins(:user_portfolio_permissions).where(
          user_portfolio_permissions: { user_id: user.id, permission_level: "crud" }
        )
      )
  }

  # =============================================================
  # Public Methods
  # =============================================================

  # == total_invested_value
  #
  # @author Moisés Reis
  #
  # Calculates the sum of all invested capital across all funds in this portfolio.
  #
  # Returns:: - The total invested value as a BigDecimal.
  def total_invested_value
    fund_investments.sum(:total_invested_value) || BigDecimal("0")
  end

  # Returns cached calculation progress for the given month.
  #
  # @param month [String] Month string in "%Y-%m" format.
  # @return [Hash] Progress data with percent, step, and done keys.
  def calculation_progress_for(month)
    Rails.cache.read("calc_progress_#{id}_#{month}") ||
      { percent: 0, step: "Aguardando…", done: false }
  end

  # == total_quotas_held
  #
  # @author Moisés Reis
  #
  # Aggregates the total number of quotas held across all individual investments.
  #
  # Returns:: - The total quantity of quotas as a BigDecimal.
  def total_quotas_held
    fund_investments.sum(:total_quotas_held) || BigDecimal("0")
  end

  # == total_gain
  #
  # @author Moisés Reis
  #
  # Computes the total financial profit or loss realised by the portfolio.
  #
  # Returns:: - The total gain as a BigDecimal.
  def total_gain
    fund_investments.includes(:investment_fund, :applications, :redemptions).sum(&:total_gain)
  end

  # == total_applications
  #
  # @author Moisés Reis
  #
  # Calculates the gross sum of all financial contributions made to this fund.
  #
  # Returns::
  # - The total amount applied to the fund as a BigDecimal.
  def total_applications
    BigDecimal(applications.sum(:financial_value).to_s)
  end

  # == total_redemptions
  # @author Moisés Reis
  #
  # Sums the total liquid value of all withdrawals performed by the user.
  #
  # Returns::
  # - The total amount redeemed from the fund as a BigDecimal.
  def total_redemptions
    BigDecimal(redemptions.sum(:redeemed_liquid_value).to_s)
  end

  # == valid_allocations?
  #
  # @author Moisés Reis
  #
  # Returns::
  # - True if allocations are valid, false otherwise.
  #
  def valid_allocations?
    fund_investments.sum(:percentage_allocation) <= BigDecimal("100")
  end

  # == self.ransackable_attributes
  #
  # @author Moisés Reis
  #
  # Specifies which portfolio attributes are available for Ransack searches.
  #
  # Returns:: - An array of searchable attribute names.
  def self.ransackable_attributes(auth_object = nil)
    %w[id name created_at updated_at user_id]
  end

  # == self.ransackable_associations
  #
  # @author Moisés Reis
  #
  # Specifies which associations are available for Ransack searches.
  #
  # Returns:: - An array of searchable association names.
  def self.ransackable_associations(auth_object = nil)
    %w[user]
  end

  private

  # == reconstruct_quotas_at
  #
  # @author Moisés Reis
  #
  # Calculates the net number of quotas held for a given fund investment
  # up to and including a specific date, by summing all applications and
  # subtracting all redemptions cotized on or before that date.
  #
  # Parameters:: - *fund_investment* - The FundInvestment record to calculate quotas for.
  #              - *date*            - The cutoff date for the quota reconstruction.
  #
  # Returns:: - The net quota balance as a BigDecimal.
  def reconstruct_quotas_at(fund_investment, date)
    apps = fund_investment.applications.where("cotization_date <= ?", date).sum(:number_of_quotas)
    reds = fund_investment.redemptions.where("cotization_date <= ?", date).sum(:redeemed_quotas)
    BigDecimal(apps.to_s) - BigDecimal(reds.to_s)
  end
end
