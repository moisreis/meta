# Represents a user's collection of investment funds and
# financial assets.
#
# A Portfolio organises holdings, tracks performance history,
# manages user permissions, and aggregates investment data to
# calculate total value, gains, and allocation metrics across
# multiple time periods.
#
# This model does NOT calculate financial returns directly.
# Portfolio return calculations belong to calculators under
# the Portfolios::Calculators namespace.
#
# @author Moisés Reis

class Portfolio < ApplicationRecord

  # =============================================================
  #                         ASSOCIATIONS
  # =============================================================

  belongs_to :user

  has_many :checking_accounts, dependent: :destroy
  has_many :fund_investments, dependent: :destroy
  has_many :investment_funds, through: :fund_investments
  has_many :user_portfolio_permissions, dependent: :destroy
  has_many :authorized_users, through: :user_portfolio_permissions, source: :user
  has_many :performance_histories, dependent: :destroy
  has_many :portfolio_normative_articles, dependent: :destroy
  has_many :normative_articles, through: :portfolio_normative_articles

  # =============================================================
  #                           VALIDATIONS
  # =============================================================

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :annual_interest_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, presence: true

  # =============================================================
  #                     NESTED ATTRIBUTES
  # =============================================================

  accepts_nested_attributes_for :portfolio_normative_articles,
                                 allow_destroy: true,
                                 reject_if: :all_blank

  # =============================================================
  #                             SCOPES
  # =============================================================

  # --- AUTHORIZATION SCOPES ------------------------------------

  # Returns portfolios accessible to a specific user.
  #
  # Includes portfolios owned by the user or shared
  # through explicit portfolio permissions.
  #
  # @param user [User]
  #   User requesting access.
  #
  # @return [ActiveRecord::Relation<Portfolio>]
  scope :for_user, ->(user) {
    left_joins(:user_portfolio_permissions)
      .where("portfolios.user_id = ? OR user_portfolio_permissions.user_id = ?", user.id, user.id)
      .distinct
  }

  # Returns portfolios readable by a specific user.
  #
  # @param user [User]
  #   User requesting visibility access.
  #
  # @return [ActiveRecord::Relation<Portfolio>]
  scope :readable_by, ->(user) {
    where(user_id: user.id)
      .or(joins(:user_portfolio_permissions).where(user_portfolio_permissions: { user_id: user.id }))
  }

  # Returns portfolios manageable by a specific user.
  #
  # @param user [User]
  #   User requesting management access.
  #
  # @return [ActiveRecord::Relation<Portfolio>]
  scope :manageable_by, ->(user) {
    where(user_id: user.id)
      .or(
        joins(:user_portfolio_permissions).where(
          user_portfolio_permissions: { user_id: user.id, permission_level: "crud" }
        )
      )
  }

  # =============================================================
  #                    AGGREGATION & METRICS
  # =============================================================

  # --- CAPITAL TOTALS ------------------------------------------

  # Calculates the sum of all invested capital across
  # all funds in this portfolio.
  #
  # @return [BigDecimal]
  #   Total invested capital value.
  def total_invested_value
    fund_investments.sum(:total_invested_value) || BigDecimal("0")
  end

  # Aggregates the total number of quotas held across
  # all individual investments.
  #
  # @return [BigDecimal]
  #   Total quantity of quotas.
  def total_quotas_held
    fund_investments.sum(:total_quotas_held) || BigDecimal("0")
  end

  # Computes the total financial profit or loss
  # realised by the portfolio.
  #
  # @return [BigDecimal]
  #   Total gain value.
  def total_gain
    fund_investments.includes(:investment_fund, :applications, :redemptions).sum(&:total_gain)
  end

  # --- CASH FLOW TOTALS ----------------------------------------

  # Calculates the gross sum of all financial
  # contributions made to this portfolio.
  #
  # @return [BigDecimal]
  #   Total application value.
  def total_applications
    BigDecimal(applications.sum(:financial_value).to_s)
  end

  # Sums the total liquid value of all withdrawals
  # performed by the user.
  #
  # @return [BigDecimal]
  #   Total redemption value.
  def total_redemptions
    BigDecimal(redemptions.sum(:redeemed_liquid_value).to_s)
  end

  # --- ALLOCATION VALIDATION -----------------------------------

  # Checks whether allocation percentages are within
  # the admissible limit.
  #
  # @return [Boolean]
  #   True if total allocation does not exceed 100%.
  def valid_allocations?
    fund_investments.sum(:percentage_allocation) <= BigDecimal("100")
  end

  # --- CALCULATION PROGRESS ------------------------------------

  # Returns cached calculation progress for a given month.
  #
  # @param month [String] Month string in "%Y-%m" format.
  #
  # @return [Hash]
  #   Progress data with percent, step, and done keys.
  def calculation_progress_for(month)
    Rails.cache.read("calc_progress_#{id}_#{month}") ||
      { percent: 0, step: "Aguardando…", done: false }
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
    %w[id name created_at updated_at user_id]
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
    %w[user]
  end

  private

  # =============================================================
  #                      QUOTA RECONSTRUCTION
  # =============================================================

  # Calculates the net number of quotas held for a
  # given fund investment up to a specific date.
  #
  # Sums all applications and subtracts all redemptions
  # cotized on or before that date.
  #
  # @param fund_investment [FundInvestment]
  #   The investment to calculate quotas for.
  #
  # @param date [Date]
  #   Cutoff date for the quota reconstruction.
  #
  # @return [BigDecimal]
  #   Net quota balance.
  def reconstruct_quotas_at(fund_investment, date)
    apps = fund_investment.applications.where("cotization_date <= ?", date).sum(:number_of_quotas)
    reds = fund_investment.redemptions.where("cotization_date <= ?", date).sum(:redeemed_quotas)
    BigDecimal(apps.to_s) - BigDecimal(reds.to_s)
  end
end
