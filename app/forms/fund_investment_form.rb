# frozen_string_literal: true

# Form object responsible for validating and normalizing
# fund investment input data before persistence.
#
# Encapsulates attribute coercion, validation rules,
# association integrity checks, and model attribute
# transformation logic used by service objects.
#
# Provides an ActiveModel-compatible interface for
# reusable form rendering and validation workflows.
#
# @author Moisés Reis
#
# ATTRIBUTE GROUPS:
#   - Investment References
#   - Allocation Metrics
#   - Financial Totals
class FundInvestmentForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  # =============================================================
  #                          MODEL NAME
  # =============================================================

  # Overrides the default ActiveModel naming behavior so the
  # form behaves like {FundInvestment} inside Rails form helpers.
  #
  # @return [ActiveModel::Name]
  def self.model_name
    ActiveModel::Name.new(
      self,
      nil,
      "FundInvestment"
    )
  end

  # =============================================================
  #                          ATTRIBUTES
  # =============================================================

  # --- INVESTMENT REFERENCES -------------------------------

  # Investment fund identifier.
  #
  # @return [Integer, nil]
  attribute :investment_fund_id, :integer

  # Portfolio identifier.
  #
  # @return [Integer, nil]
  attribute :portfolio_id, :integer

  # --- ALLOCATION METRICS ----------------------------------

  # Percentage allocation inside the portfolio.
  #
  # @return [BigDecimal, nil]
  attribute :percentage_allocation, :decimal

  # --- FINANCIAL TOTALS ------------------------------------

  # Total invested capital amount.
  #
  # @return [BigDecimal, nil]
  attribute :total_invested_value, :decimal

  # Total quantity of held quotas.
  #
  # @return [BigDecimal, nil]
  attribute :total_quotas_held, :decimal

  # =============================================================
  #                          VALIDATIONS
  # =============================================================

  validates :investment_fund_id,
            presence: true

  validates :portfolio_id,
            presence: true

  validates :percentage_allocation,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 100
            }

  validates :total_invested_value,
            numericality: {
              greater_than_or_equal_to: 0
            },
            allow_nil: true

  validates :total_quotas_held,
            numericality: {
              greater_than_or_equal_to: 0
            },
            allow_nil: true

  validate :validate_associations_exist

  # =============================================================
  #                        ATTRIBUTE EXPORT
  # =============================================================

  # Converts form attributes into a persistence-compatible
  # hash used by ActiveRecord models and service objects.
  #
  # @return [Hash]
  def to_model_attributes
    {
      investment_fund_id: investment_fund_id,
      portfolio_id: portfolio_id,
      percentage_allocation: percentage_allocation,
      total_invested_value: total_invested_value,
      total_quotas_held: total_quotas_held
    }
  end

  # =============================================================
  #                       FACTORY CONSTRUCTORS
  # =============================================================

  # Builds a form instance from an existing fund investment.
  #
  # Useful for edit/update flows and form repopulation.
  #
  # @param fund_investment [FundInvestment]
  #
  # @return [FundInvestmentForm]
  def self.from_fund_investment(fund_investment)
    new(
      investment_fund_id: fund_investment.investment_fund_id,
      portfolio_id: fund_investment.portfolio_id,
      percentage_allocation: fund_investment.percentage_allocation,
      total_invested_value: fund_investment.total_invested_value,
      total_quotas_held: fund_investment.total_quotas_held
    )
  end

  private

  # =============================================================
  #                       ASSOCIATION VALIDATIONS
  # =============================================================

  # Validates referenced association existence.
  #
  # @return [void]
  def validate_associations_exist
    validate_investment_fund_exists
    validate_portfolio_exists
  end

  # --- INVESTMENT FUND EXISTENCE ---------------------------

  # Ensures the referenced investment fund exists.
  #
  # @return [void]
  def validate_investment_fund_exists
    return if investment_fund_id.blank?
    return if InvestmentFund.exists?(investment_fund_id)

    errors.add(
      :investment_fund_id,
      :invalid
    )
  end

  # --- PORTFOLIO EXISTENCE ---------------------------------

  # Ensures the referenced portfolio exists.
  #
  # @return [void]
  def validate_portfolio_exists
    return if portfolio_id.blank?
    return if Portfolio.exists?(portfolio_id)

    errors.add(
      :portfolio_id,
      :invalid
    )
  end
end