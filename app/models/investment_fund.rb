# === investment_fund
#
# @author Moisés Reis
# @added 11/25/2025
# @package *Meta*
# @description This class represents a single financial product, specifically an investment fund.
#              It stores the fund's public details, official identification (**cnpj**),
#              and provides methods to access its historical and current quota (share) price.
# @category *Model*
#
# Usage:: - *[What]* This code block defines a specific investment product
#           that users can invest in through a **FundInvestment** record.
#         - *[How]* It uses the CNPJ as a unique key to fetch daily pricing data
#           from the **FundValuation** table and links to regulatory **NormativeArticles**.
#         - *[Why]* The application needs this central class to standardize fund data,
#           validate official identifiers, and provide accurate, timely pricing for all portfolio calculations.
#
# Attributes:: - *cnpj* @string - The unique official identifier (CNPJ) for the investment fund.
#              - *fund_name* @string - The official registered name of the investment fund.
#              - *administrator_name* @string - The name of the institution responsible for managing the fund.
#              - *originator_fund* @string - The name of the fund that originated this investment (if applicable).
#
class InvestmentFund < ApplicationRecord

  # Explanation:: This establishes a one-to-many relationship, linking this fund to all
  #               **FundInvestment** records that represent users holding units in it.
  has_many :fund_investments, dependent: :destroy

  # Explanation:: This establishes a many-to-many relationship, allowing easy retrieval
  #               of all **Portfolios** that hold an investment in this fund.
  has_many :portfolios, through: :fund_investments

  # Explanation:: This establishes a linking table for the many-to-many relationship
  #               with regulatory articles, and ensures the links are destroyed on deletion.
  has_many :investment_fund_articles, dependent: :destroy

  # Explanation:: This establishes a many-to-many relationship, linking the fund
  #               to the specific **NormativeArticles** that govern it.
  has_many :normative_articles, through: :investment_fund_articles

  # Explanation:: This establishes a link to the daily quota price records (**FundValuation**)
  #               using the fund's `cnpj` as the primary key for the association.
  has_many :fund_valuation, class_name: 'FundValuation', foreign_key: 'fund_cnpj', primary_key: 'cnpj', dependent: :destroy

  # Explanation:: This validates that the fund's CNPJ is present, unique, and adheres
  #               to the required official Brazilian format (XX.XXX.XXX/XXXX-XX).
  validates :cnpj, presence: true, uniqueness: true, format: {
    with: /\A\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}\z/,
    message: "must be in the format XX.XXX.XXX/XXXX-XX"
  }

  # Explanation:: This validates that the official name of the fund is present
  #               and must be between 3 and 200 characters long.
  validates :fund_name, presence: true, length: {
    minimum: 3,
    maximum: 200
  }

  # Explanation:: This validates that the name of the fund's administrator is present
  #               and must be between 3 and 100 characters long.
  validates :administrator_name, presence: true, length: {
    minimum: 3,
    maximum: 100
  }

  # Explanation:: This validates the length of the optional originator fund name
  #               and allows the field to be left blank.
  validates :originator_fund, length: { maximum: 200 }, allow_blank: true

  # Explanation:: This defines a query scope that easily retrieves all funds managed
  #               by a specific administrator, identified by name.
  scope :by_administrator, ->(admin) { where(administrator_name: admin) }

  # Explanation:: This defines a query scope that finds all funds that currently have
  #               at least one **FundInvestment** record, meaning they are actively held by users.
  scope :active, -> { joins(:fund_investments).distinct }

  accepts_nested_attributes_for :investment_fund_articles, allow_destroy: true

  # == latest_quota_value
  #
  # @author Moisés Reis
  # @category *Value*
  #
  # Value:: This method retrieves the most recent quota price (share value) available for the fund from the valuation history.
  #         It is the standard method used by **FundInvestment** to calculate the current market value.
  #
  def latest_quota_value
    fund_valuation.order(date: :desc).first&.quota_value
  end

  # == quota_value_on
  #
  # @author Moisés Reis
  # @category *Value*
  #
  # Value:: This method retrieves the specific quota price (share value) that was valid on a given date.
  #         It is used to perform historical performance calculations based on past prices.
  #
  # Attributes:: - *@date* @date - The specific calendar date for which the price is required.
  #
  def quota_value_on(date)
    fund_valuation.find_by(date: date)&.quota_value
  end

  # == total_invested
  #
  # @author Moisés Reis
  # @category *Aggregation*
  #
  # Aggregation:: This method calculates the sum of all money invested across all **FundInvestment** records that hold this fund.
  #              It provides the gross amount invested by all users into this product.
  #
  def total_invested
    fund_investments.sum(:total_invested_value) || BigDecimal('0')
  end

  # == ransackable_attributes
  #
  # @author Moisés Reis
  # @category *Query*
  #
  # Query:: This method defines which columns of the **InvestmentFund** model can be safely searched or filtered by users through advanced query tools like Ransack.
  #         It explicitly lists all the safe, searchable attributes.
  #
  def self.ransackable_attributes(auth_object = nil)
    [
      "administrator_name",
      "cnpj",
      "created_at",
      "fund_name",
      "id",
      "id_value",
      "originator_fund",
      "updated_at"
    ]
  end
end