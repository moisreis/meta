# === investment_fund.rb
#
# Description:: Represents a financial investment fund within the system.
#               This model manages the fund's identification, associated
#               regulatory articles, and historical quota valuations.
#
# Usage:: - *What* - Serves as the central repository for investment fund metadata.
#         - *How* - It links funds to portfolios, tracks regulatory compliance,
#           and provides methods to query historical asset pricing.
#         - *Why* - Necessary to provide a standardised reference for funds across
#           user portfolios and performance reporting.
#
# Attributes:: - *@cnpj* [String] - The unique tax identification number for the fund.
#              - *@fund_name* [String] - The formal name of the investment fund.
#              - *@administrator_name* [String] - The entity responsible for managing the fund.
#              - *@originator_fund* [String] - The name of the originating or parent fund, if applicable.
#
class InvestmentFund < ApplicationRecord

  has_many :fund_investments,         dependent: :destroy
  has_many :portfolios,               through: :fund_investments
  has_many :investment_fund_articles, dependent: :destroy
  has_many :normative_articles,       through: :investment_fund_articles
  has_many :fund_valuations,
           class_name:  "FundValuation",
           foreign_key: "fund_cnpj",
           primary_key: "cnpj",
           dependent:   :destroy

  validates :cnpj, presence: true, uniqueness: true, format: {
    with:    /\A\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}\z/,
    message: "deve estar no formato XX.XXX.XXX/XXXX-XX"
  }
  validates :fund_name,          presence: true, length: { minimum: 3, maximum: 200 }
  validates :administrator_name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :originator_fund,    length: { maximum: 200 }, allow_blank: true

  # =============================================================
  # Scopes
  # =============================================================

  scope :by_administrator, ->(admin) { where(administrator_name: admin) }
  scope :active,           -> { joins(:fund_investments).distinct }

  # Returns all funds accessible through portfolios that the given user can read.
  # Used by Ability to gate InvestmentFund read permissions for non-admin users.
  scope :readable_by, ->(user) {
    joins(fund_investments: :portfolio)
      .where(portfolios: { id: Portfolio.readable_by(user).select(:id) })
      .distinct
  }

  accepts_nested_attributes_for :investment_fund_articles, allow_destroy: true

  # =============================================================
  # Public Methods
  # =============================================================

  # == latest_quota_value
  #
  # @author Moisés Reis
  #
  # Retrieves the most recent available quota value for the investment fund.
  #
  # Returns:: - The latest quota value as a BigDecimal or nil.
  def latest_quota_value
    quota_value_on(Date.current)
  end

  # == quota_value_on
  #
  # @author Moisés Reis
  #
  # Finds the quota value for the fund on a given date, excluding weekends
  # to ensure only business day values are returned.
  #
  # Parameters:: - *date* - The date to check for a valid quota valuation.
  #
  # Returns:: - The quota value found for that date as a BigDecimal.
  def quota_value_on(date)
    fund_valuations
      .where("date <= ?", date)
      .where("EXTRACT(DOW FROM date) NOT IN (0, 6)")
      .order(date: :desc)
      .limit(1)
      .pick(:quota_value)
  end

  # == total_invested
  #
  # @author Moisés Reis
  #
  # Calculates the sum of all invested values across all portfolio holdings for this fund.
  #
  # Returns:: - The total capital invested as a BigDecimal.
  def total_invested
    fund_investments.sum(:total_invested_value) || BigDecimal("0")
  end

  # == self.ransackable_attributes
  #
  # @author Moisés Reis
  #
  # Defines which attributes are available for searching and filtering through Ransack.
  #
  # Returns:: - An array of searchable attribute names.
  def self.ransackable_attributes(auth_object = nil)
    %w[administrator_name cnpj created_at fund_name id originator_fund updated_at]
  end
end
