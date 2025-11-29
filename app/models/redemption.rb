# === redemption
#
# @author Moisés Reis
# @added 11/28/2025
# @package *Meta*
# @description This model represents a single financial redemption transaction made by a client.
#              It holds all necessary information about the withdrawal, including dates, values, and the linked investment.
# @category *Model*
#
# Usage:: - *[What]* It manages the record of money withdrawn from an investment fund.
#         - *[How]* It establishes relationships with investment and allocation records,
#           validates the data integrity, and provides methods to check the status and calculate values.
#         - *[Why]* It is necessary to track the history, status, and financial results
#           of all client withdrawals for reporting and compliance purposes.
#
# Attributes:: - *fund_investment_id* @integer - identifies the specific investment record from which the redemption is made.
#              - *redeemed_liquid_value* @decimal - stores the final amount of money received by the client after all fees and taxes.
#              - *redeemed_quotas* @decimal - represents the number of quotas (shares) sold back to the fund.
#              - *redemption_yield* @decimal - tracks the net financial gain or loss (return) resulting specifically from this redemption.
#              - *redemption_type* @string - indicates the nature of the withdrawal (e.g., partial, total, emergency).
#              - *request_date* @date - records the day the client formally initiated the redemption request.
#              - *cotization_date* @date - records the day the redemption's quota value is officially calculated and fixed.
#              - *liquidation_date* @date - records the day the final money is actually deposited into the client's bank account.
#
class Redemption < ApplicationRecord

  # Explanation:: This establishes a mandatory one-to-one relationship where a Redemption belongs to a **FundInvestment** record.
  #               A redemption cannot exist without being linked to a specific fund investment.
  belongs_to :fund_investment

  # Explanation:: This establishes a one-to-many relationship with **RedemptionAllocation** records.
  #               When a Redemption is destroyed, all its associated allocations are automatically removed as well.
  has_many :redemption_allocations, dependent: :destroy

  # Explanation:: This establishes a many-to-many relationship with **Application** records through **RedemptionAllocation**.
  #               It allows you to quickly access the original applications that were redeemed.
  has_many :applications, through: :redemption_allocations

  # Explanation:: This enforces that the investment identifier (`fund_investment_id`) must be present.
  #               Every redemption record must specify exactly which investment it is withdrawing from.
  validates :fund_investment_id, presence: true

  # Explanation:: This enforces that the request date must be present.
  #               A redemption must have a recorded initiation date to be valid.
  validates :request_date, presence: true

  # Explanation:: This validates that if the `redeemed_liquid_value` is present, it must be a number greater than zero.
  #               The liquid value can be optional (`allow_nil: true`) if the transaction is still pending, but if entered, it must be a positive value.
  validates :redeemed_liquid_value, numericality: {
    greater_than: 0
  }, allow_nil: true

  # Explanation:: This validates that if the `redeemed_quotas` value is present, it must be a number greater than zero.
  #               The number of quotas can be optional (`allow_nil: true`) but, if entered, it must represent a positive amount.
  validates :redeemed_quotas, numericality: {
    greater_than: 0
  }, allow_nil: true

  # Explanation:: This validates that if the `redemption_yield` is present, it must be a valid number (which can be positive or negative).
  #               The yield can be optional (`allow_nil: true`) if the final calculation is not yet available.
  validates :redemption_yield, numericality: true, allow_nil: true

  # Explanation:: This ensures that the `redemption_type` (if provided) is one of the allowed categories: partial, total, emergency, or scheduled.
  #               It prevents saving records with misspelled or invalid type indicators.
  validates :redemption_type, inclusion: {
    in: %w[partial total emergency scheduled],
    message: "%{value} isn't a valid redemption type"
  }, allow_blank: true

  # Explanation:: This triggers a custom validation method to ensure data integrity regarding timing.
  #               It verifies that the cotization date occurs on or after the request date.
  validate :cotization_after_request

  # Explanation:: This triggers a custom validation method to ensure data integrity regarding timing.
  #               It verifies that the liquidation date occurs on or after the cotization date.
  validate :liquidation_after_cotization

  # Explanation:: This triggers a custom validation method before saving the record.
  #               It checks that the number of quotas being redeemed is not higher than the total available in the corresponding **FundInvestment**.
  validate :sufficient_quotas_available

  # Explanation:: This defines a scope that easily retrieves all redemption records that have not yet had their quota value calculated.
  #               It finds records where the `cotization_date` field is blank (nil).
  scope :pending_cotization, -> {
    where(cotization_date: nil)
  }

  # Explanation:: This defines a scope that easily retrieves all redemption records that have been cotized but not yet paid out.
  #               It finds records where `cotization_date` is not blank but `liquidation_date` is blank.
  scope :pending_liquidation, -> {
    where.not(cotization_date: nil).where(liquidation_date: nil)
  }

  # Explanation:: This defines a scope that easily retrieves all redemption records that have completed the process.
  #               It finds records where the `liquidation_date` field is not blank.
  scope :completed, -> {
    where.not(liquidation_date: nil)
  }

  # Explanation:: This defines a scope that allows filtering redemption records by a specific type.
  #               It accepts a `type` argument and retrieves records matching that `redemption_type`.
  scope :by_type, ->(type) {
    where(redemption_type: type)
  }

  # Explanation:: This defines a scope that allows filtering redemption records requested within a specific time frame.
  #               It accepts a `start_date` and `end_date` and retrieves records where the `request_date` falls within that range.
  scope :in_date_range, ->(start_date, end_date) {
    where(request_date: start_date..end_date)
  }

  # == completed?
  #
  # @author Moisés Reis
  # @category *Status*
  #
  # Category:: This method checks the status of the redemption.
  #            It determines if the transaction is complete by looking at the liquidation date.
  #
  # Attributes:: - *@return* @boolean - returns true if the liquidation date is present (not blank), indicating the transaction is finished.
  #
  def completed?
    liquidation_date.present?
  end

  # == effective_quota_value
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Category:: This method calculates the actual value per quota for this specific redemption transaction.
  #            It divides the total liquid value by the number of quotas redeemed.
  #
  # Attributes:: - *@return* @decimal - returns the calculated quota value, or nil if the necessary liquid value or quota count is missing.
  #
  def effective_quota_value

    # Explanation:: This immediately stops the calculation and returns nil if either the liquid value or the redeemed quotas are missing, or if the quota count is zero.
    #               You cannot perform division without valid, positive values.
    return nil unless redeemed_liquid_value && redeemed_quotas && redeemed_quotas > 0

    # Explanation:: This performs the core calculation by dividing the final liquid amount received by the total number of quotas redeemed.
    #               This yields the effective price per quota for the transaction.
    redeemed_liquid_value / redeemed_quotas
  end

  # == total_allocated_quotas
  #
  # @author Moisés Reis
  # @category *Allocation*
  #
  # Category:: This method calculates the sum of all quotas that have been successfully linked (allocated) to this redemption.
  #            It provides the total quantity of quotas that are sourced from the original applications.
  #
  # Attributes:: - *@return* @decimal - returns the summed total of quotas used in all linked redemption allocations, defaulting to zero if there are no allocations.
  #
  def total_allocated_quotas
    redemption_allocations.sum(:quotas_used) || BigDecimal('0')
  end

  # == allocations_balanced?
  #
  # @author Moisés Reis
  # @category *Integrity*
  #
  # Category:: This method checks if the quantity of quotas redeemed matches the total quantity allocated from the original applications.
  #            This ensures that all quotas in the redemption have been accounted for in the allocation records.
  #
  # Attributes:: - *@return* @boolean - returns true if the total allocated quotas are exactly equal to the redeemed quotas, indicating a balanced transaction.
  #
  def allocations_balanced?

    # Explanation:: This returns false immediately if the number of redeemed quotas is not recorded.
    #               You cannot perform a balance check without knowing the target number of redeemed quotas.
    return false unless redeemed_quotas

    # Explanation:: This compares the total number of quotas summed from all **RedemptionAllocation** records against the value stored in the `redeemed_quotas` field.
    #               The values must match exactly for the transaction to be considered balanced.
    total_allocated_quotas == redeemed_quotas
  end

  # == return_percentage
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Category:: This method calculates the percentage return achieved on the capital redeemed.
  #            It uses the redemption yield relative to the original capital that generated the yield.
  #
  # Attributes:: - *@return* @decimal - returns the calculated percentage return (e.g., 5.0 for 5%), or nil if necessary values are missing or the denominator is zero.
  #
  def return_percentage

    # Explanation:: This returns nil if the yield or liquid value is missing, or if the yield itself is zero (avoiding division by zero in the denominator calculation).
    #               The calculation cannot proceed without these necessary financial fields.
    return nil unless redemption_yield && redeemed_liquid_value && redemption_yield != 0

    # Explanation:: This calculates the return percentage using the formula: Yield / (Liquid Value - Yield) * 100.
    #               The denominator represents the initial capital invested that generated the yield.
    (redemption_yield / (redeemed_liquid_value - redemption_yield)) * 100
  end

  private

  # == cotization_after_request
  #
  # @author Moisés Reis
  # @category *Validation*
  #
  # Category:: This private validation ensures the cotization date is chronologically correct.
  #            The date when the quota value is fixed cannot precede the date the request was initiated.
  #
  # Attributes:: - *@error* @string - adds an error message to the `cotization_date` attribute if the date order is incorrect.
  #
  def cotization_after_request

    # Explanation:: This stops execution if either date is missing, allowing validation only when both fields are present.
    #               If a date is missing, the basic `presence: true` validation handles it elsewhere.
    return unless request_date && cotization_date

    # Explanation:: This checks if the cotization date is earlier than the request date.
    #               If it is earlier, it adds a descriptive error message to the record, preventing it from saving.
    if cotization_date < request_date
      errors.add(:cotization_date, "cannot be earlier than the request date")
    end
  end

  # == liquidation_after_cotization
  #
  # @author Moisés Reis
  # @category *Validation*
  #
  # Category:: This private validation ensures the liquidation date follows the cotization date.
  #            The money payment date cannot occur before the date the quota value was consolidated.
  #
  # Attributes:: - *@error* @string - adds an error message to the `liquidation_date` attribute if the date order is incorrect.
  #
  def liquidation_after_cotization

    # Explanation:: This stops execution if either date is missing, allowing validation only when both fields are present.
    #               If a date is missing, validation is skipped here.
    return unless cotization_date && liquidation_date

    # Explanation:: This checks if the liquidation date is earlier than the cotization date.
    #               If the check fails, it adds a descriptive error message to the `liquidation_date` field.
    if liquidation_date < cotization_date
      errors.add(:liquidation_date, "cannot be earlier than the cotization date")
    end
  end

  # == sufficient_quotas_available
  #
  # @author Moisés Reis
  # @category *Validation*
  #
  # Category:: This private validation checks if the investment holds enough quotas to cover the requested redemption amount.
  #            You cannot redeem more quotas than the client currently possesses in the fund.
  #
  # Attributes:: - *@error* @string - adds an error message to the `redeemed_quotas` attribute if the requested amount exceeds the available total.
  #
  def sufficient_quotas_available

    # Explanation:: This stops the validation if the required linked **fund_investment** or the number of redeemed quotas is missing.
    #               The quota check requires both the investment context and the amount being redeemed.
    return unless fund_investment && redeemed_quotas

    # Explanation:: This compares the number of quotas being redeemed against the total held by the **FundInvestment** record.
    #               If the redemption amount is greater, it adds an error preventing the transaction.
    if redeemed_quotas > fund_investment.total_quotas_held
      errors.add(:redeemed_quotas, "cannot exceed available quotas in the fund investment")
    end
  end

  # == self.ransackable_attributes
  #
  # @author Moisés Reis
  # @category *Ransack*
  #
  # Category:: This class method defines which attributes of the **Redemption** model can be searched or sorted using the Ransack gem.
  #            It explicitly lists the database columns available for filtering in the front-end.
  #
  # Attributes:: - *@return* @array - returns a list of safe attribute names that Ransack is allowed to access.
  #
  def self.ransackable_attributes(auth_object = nil)
    [
      "cotization_date",
      "created_at",
      "fund_investment_id",
      "id",
      "liquidation_date",
      "redeemed_liquid_value",
      "redeemed_quotas",
      "redemption_type",
      "redemption_yield",
      "request_date",
      "updated_at"
    ]
  end

  # == self.ransackable_associations
  #
  # @author Moisés Reis
  # @category *Ransack*
  #
  # Category:: This class method defines which associations of the **Redemption** model can be searched or filtered through the Ransack gem.
  #            It makes associated models available for complex filtering queries.
  #
  # Attributes:: - *@return* @array - returns a list of safe association names that Ransack is allowed to use in queries.
  #
  def self.ransackable_associations(auth_object = nil)
    [
      "applications",
      "fund_investment",
      "redemption_allocations"
    ]
  end
end