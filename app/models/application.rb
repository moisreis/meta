# === application
#
# @author Moisés Reis
# @added 11/25/2025
# @package *Meta*
# @description This class represents a financial transaction where a user makes a new investment (subscription) into a fund.
#              It manages the financial details, quota allocation, and transaction lifecycle through key dates.
#              The explanations are in the present simple tense.
# @category *Model*
#
# Usage:: - *[What]* This code block manages the record of
#           a new investment or subscription made by a user into a fund.
#         - *[How]* It saves the financial value, calculates the number of quotas,
#           enforces rules about transaction dates, and tracks quota usage for redemptions.
#         - *[Why]* It ensures that all investment requests are properly recorded,
#           validated against financial rules, and correctly matched against future redemptions.
#
# Attributes:: - *financial_value* @decimal - The monetary amount invested in the application.
#              - *request_date* @date - The date the investment request is submitted.
#              - *cotization_date* @date - The date the quota price is determined.
#              - *liquidation_date* @date - The date the funds are settled.
#
class Application < ApplicationRecord

  # Explanation:: This establishes a direct link, indicating that every application belongs
  #               to a single parent **FundInvestment** record, which represents the entire holding.
  belongs_to :fund_investment

  # Explanation:: This establishes a one-to-many relationship, indicating that an application's
  #               quotas can be allocated to multiple **RedemptionAllocation** records when the user withdraws funds.
  has_many :redemption_allocations, dependent: :destroy

  # Explanation:: This ensures that an application record is always associated with a valid
  #               **FundInvestment** before it can be saved to the database.
  validates :fund_investment_id, presence: true

  # Explanation:: This validates that the date the user requests the investment is
  #               always present in the record.
  validates :request_date, presence: true

  # Explanation:: This validates that the monetary amount of the investment is present
  #               and must be a positive number greater than zero.
  validates :financial_value, presence: true, numericality: { greater_than: 0 }

  # Explanation:: This validates that the number of quotas acquired is a positive number
  #               and allows the field to be empty if the quota calculation is pending.
  validates :number_of_quotas, numericality: { greater_than: 0 }, allow_nil: true

  # Explanation:: This validates that the price of the quota at the time of investment is a
  #               positive number, but allows the field to be empty if the cotization is pending.
  validates :quota_value_at_application, numericality: { greater_than: 0 }, allow_nil: true

  # Explanation:: This calls a custom private validation method to ensure that the
  #               cotization date does not occur before the request date.
  validate :cotization_after_request

  # Explanation:: This calls a custom private validation method to ensure that the
  #               liquidation date does not occur before the cotization date.
  validate :liquidation_after_cotization

  # Explanation:: This calls a custom private validation method to check if the financial
  #               value is mathematically consistent with the number of quotas and the quota value.
  validate :quota_calculation_consistency

  # Explanation:: This defines a query scope that easily retrieves all application records
  #               for which the quota cotization date has not yet been set.
  scope :pending_cotization, -> { where(cotization_date: nil) }

  # Explanation:: This defines a query scope that finds applications that have a cotization date
  #               but are still waiting for the final liquidation date to be set.
  scope :pending_liquidation, -> { where.not(cotization_date: nil).where(liquidation_date: nil) }

  # Explanation:: This defines a query scope that returns all application records where the
  #               transaction lifecycle is fully complete, indicated by a present liquidation date.
  scope :completed, -> { where.not(liquidation_date: nil) }

  # Explanation:: This defines a query scope that allows filtering applications by the
  #               period during which the investment request was made.
  scope :in_date_range, ->(start_date, end_date) { where(request_date: start_date..end_date) }

  # == completed?
  #
  # @author Moisés Reis
  # @category *Status*
  #
  # Status:: This method quickly checks and confirms if the entire investment application process is finalized.
  #          It determines completion by checking if the liquidation date field has been filled out.
  #
  def completed?
    liquidation_date.present?
  end

  # == available_quotas
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Calculation:: This method calculates the total number of quotas from this investment that are still available for the user to redeem.
  #              It subtracts any quotas already used by previous redemption requests.
  #
  def available_quotas

    # Explanation:: This returns a zero value for quotas if the `number_of_quotas` is
    #               not yet set on the record, preventing calculation errors.
    return BigDecimal('0') unless number_of_quotas

    # Explanation:: This sums up the total number of quotas that have already been
    #               allocated and used by child redemption records.
    allocated = redemption_allocations.sum(:quotas_used) || BigDecimal('0')

    # Explanation:: This calculates the remaining balance of quotas by subtracting the
    #               allocated amount from the total number of quotas purchased.
    number_of_quotas - allocated
  end

  # == fully_allocated?
  #
  # @author Moisés Reis
  # @category *Status*
  #
  # Status:: This method checks if all quotas acquired through this application have been fully used up by redemption requests.
  #          It returns true if the available quota count is zero or less.
  #
  def fully_allocated?
    available_quotas <= 0
  end

  # == calculated_quota_value
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Calculation:: This method dynamically calculates the effective quota value by dividing the total investment amount by the number of quotas received.
  #              It is used as a consistency check or when the actual quota value is missing.
  #
  def calculated_quota_value

    # Explanation:: This returns nil if the necessary values (`financial_value` or `number_of_quotas`)
    #               are missing or if the quota count is zero, preventing division by zero.
    return nil unless financial_value && number_of_quotas && number_of_quotas > 0

    # Explanation:: This performs the core calculation: dividing the total money invested
    #               by the quantity of quotas purchased to find the unit quota price.
    financial_value / number_of_quotas
  end

  private

  # == cotization_after_request
  #
  # @author Moisés Reis
  # @category *Validation*
  #
  # Validation:: This custom validation ensures that the date when the quota price is determined (cotization_date)
  #              must logically fall on or after the date the investment was requested (request_date).
  #
  def cotization_after_request

    # Explanation:: This immediately exits the validation if either of the dates is missing,
    #               as the comparison cannot be performed.
    return unless request_date && cotization_date

    # Explanation:: This checks if the cotization date is earlier than the request date,
    #               and if so, it adds a validation error message to the record.
    if cotization_date < request_date
      errors.add(:cotization_date, "cannot be before request date")
    end
  end

  # == liquidation_after_cotization
  #
  # @author Moisés Reis
  # @category *Validation*
  #
  # Validation:: This custom validation ensures that the date when the investment funds are actually settled (liquidation_date)
  #              must logically occur on or after the quota pricing date (cotization_date).
  #
  # Attributes:: - *None* - This method uses the record's date fields.
  #
  def liquidation_after_cotization

    # Explanation:: This immediately exits the validation if either the cotization or
    #               liquidation date is missing.
    return unless cotization_date && liquidation_date

    # Explanation:: This checks if the liquidation date is earlier than the cotization date,
    #               and if so, it adds a validation error message to the record.
    if liquidation_date < cotization_date
      errors.add(:liquidation_date, "cannot be before cotization date")
    end
  end

  # == quota_calculation_consistency
  #
  # @author Moisés Reis
  # @category *Validation*
  #
  # Validation:: This custom validation checks if the total financial value equals the product of
  #              the number of quotas and the quota value, allowing a small tolerance for floating-point inaccuracies.
  #              It ensures the stored data is mathematically consistent.
  #
  def quota_calculation_consistency

    # Explanation:: This exits the validation if any of the three key calculation fields
    #               are missing, as a full consistency check is not possible.
    return unless financial_value && number_of_quotas && quota_value_at_application

    # Explanation:: This calculates the expected total financial value by multiplying
    #               the number of quotas by the unit quota value.
    expected_value = number_of_quotas * quota_value_at_application

    # Explanation:: This defines a small acceptable margin of error (tolerance) for
    #               comparing two floating-point (BigDecimal) numbers.
    tolerance = BigDecimal('0.01')

    # Explanation:: This checks if the absolute difference between the stored financial value
    #               and the calculated expected value exceeds the defined tolerance.
    if (financial_value - expected_value).abs > tolerance
      errors.add(:base, "financial value doesn't match quotas × quota value")
    end
  end

  # == ransackable_attributes
  #
  # @author Moisés Reis
  # @category *Query*
  #
  # Query:: This method defines which columns of the **Application** model can be searched or filtered by users through advanced query tools like Ransack.
  #         It explicitly lists all the safe, searchable attributes.
  #
  # Attributes:: - *@auth_object* @object - The optional user object used for authorization checks.
  #
  def self.ransackable_attributes(auth_object = nil)
    [
      "cotization_date",
      "created_at",
      "financial_value",
      "fund_investment_id",
      "id",
      "id_value",
      "liquidation_date",
      "number_of_quotas",
      "quota_value_at_application",
      "request_date",
      "updated_at"
    ]
  end

  # == ransackable_associations
  #
  # @author Moisés Reis
  # @category *Query*
  #
  # Query:: This method defines which associated models (relationships) of the **Application** model can be included in search and filtering operations by Ransack.
  #         It ensures only valid relationships are exposed for querying.
  #
  # Attributes:: - *@auth_object* @object - The optional user object used for authorization checks.
  #
  def self.ransackable_associations(auth_object = nil)
    [
      "fund_investment",
      "redemption_allocations"
    ]
  end
end