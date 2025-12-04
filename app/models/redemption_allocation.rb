# === redemption_allocation
#
# @author Moisés Reis
# @added 12/3/2025
# @package *Meta*
# @description This model represents the link between a **Redemption** and an
#              **Application**. It stores how many quotas from a specific
#              application are used to fulfill a redemption request. It handles
#              validation and basic financial calculations in a clean and
#              structured way.
# @category *Model*
#
# Usage:: - *[What]* This code block defines a model that represents the usage
#           of quotas from an application to satisfy a redemption.
#         - *[How]* It does this by connecting a redemption and an application,
#           validating the data, and exposing methods that calculate cost,
#           value, gain, return, and time period.
#         - *[Why]* It needs to be in the app because redemption events require
#           precise tracking of which applications they consume, ensuring
#           accuracy in fund accounting and investment performance evaluation.
#
# Attributes:: - *redemption_id* @integer - identifies the linked redemption.
#              - *application_id* @integer - identifies the linked application.
#              - *quotas_used* @decimal - specifies how many quotas are used.
#
class RedemptionAllocation < ApplicationRecord

  # Explanation:: This line declares an association that connects this record to
  #               a specific **Redemption**. It lets the model access redemption
  #               attributes and ensures proper relational mapping.
  belongs_to :redemption

  # Explanation:: This declares an association linking this allocation to a
  #               specific **Application**. It enables the model to retrieve
  #               application-related data such as quota value and dates.
  belongs_to :application

  # Explanation:: This validation ensures that a redemption is always present.
  #               It prevents allocations from existing without a linked
  #               redemption event.
  validates :redemption_id, presence: true

  # Explanation:: This validation requires the presence of an application. It
  #               guarantees that the allocation belongs to an actual quota
  #               source.
  validates :application_id, presence: true

  # Explanation:: This validation ensures that quotas_used exists and is a
  #               positive number. It prevents invalid or negative allocations.
  validates :quotas_used, presence: true, numericality: {
    greater_than: 0
  }

  # Explanation:: This calls a custom validation method that checks if the
  #               application has enough quotas available to support the
  #               allocation.
  validate :sufficient_quotas_in_application

  # Explanation:: This triggers a rule ensuring the redemption and application
  #               belong to the same **FundInvestment**, preventing mismatches.
  validate :applications_belong_to_same_fund_investment

  # Explanation:: This enforces uniqueness so that the same application cannot
  #               be allocated twice for a single redemption.
  validate :unique_allocation_per_redemption_application

  # Explanation:: This scope allows quick filtering of allocations belonging to
  #               a specific redemption. It keeps queries readable and consistent.
  scope :for_redemption, ->(redemption) {
    where(redemption: redemption)
  }

  # Explanation:: This scope filters allocations by application. It groups
  #               records linked to the same application source.
  scope :for_application, ->(application) {
    where(application: application)
  }

  # Explanation:: This scope orders allocations from the largest to the smallest
  #               based on quotas used. It is useful for reporting and summaries.
  scope :by_allocation_size, -> {
    order(quotas_used: :desc)
  }

  # == identifier
  #
  # @author Moisés Reis
  # @category *Identification*
  #
  # Category:: This method generates a friendly label that describes the
  #            allocation using dates and quotas. It helps users quickly
  #            recognize which application and redemption are involved.
  #
  # Attributes:: - *@identifier* - returns the formatted descriptive string.
  #
  def identifier

    # Explanation:: This retrieves the redemption date and formats it in a
    #               standard pattern. If it is missing, it shows "Unknown".
    redemption_date = redemption&.request_date&.strftime('%Y-%m-%d') || "Unknown"

    # Explanation:: This retrieves the application date in the same format. It
    #               also falls back to "Unknown" if the date is not present.
    application_date = application&.request_date&.strftime('%Y-%m-%d') || "Unknown"

    # Explanation:: This returns the final human-readable string describing how
    #               the application contributes quotas to the redemption.
    "Redemption #{redemption_date} using the application #{application_date} with (#{quotas_used} quotas)"
  end

  # == cost_basis
  #
  # @category *Finance*
  #
  # Category:: This method calculates how much the used quotas originally cost.
  #            It uses the application's quota value to compute the investment’s
  #            historical cost.
  #
  # Attributes:: - *@cost_basis* - returns the calculated monetary cost.
  #
  def cost_basis

    # Explanation:: This ensures both the application quota value and
    #               quotas_used exist before calculating. If they don't, it
    #               returns nil.
    return nil unless application&.quota_value_at_application && quotas_used

    # Explanation:: This multiplies the quotas used by their purchase value,
    #               producing the total historical cost.
    quotas_used * application.quota_value_at_application
  end

  # == current_market_value
  #
  # @category *Finance*
  #
  # Category:: This method calculates the current value of the allocated quotas
  #            using the fund’s latest quota price. It helps measure present
  #            investment worth.
  #
  # Attributes:: - *@current_market_value* - returns the updated market value.
  #
  def current_market_value

    # Explanation:: This checks whether a current quota price exists and ensures
    #               quotas_used is available. Without these, it returns nil.
    return nil unless redemption&.fund_investment&.investment_fund&.latest_quota_value && quotas_used

    # Explanation:: This multiplies quotas_used by the most recent quota value,
    #               producing the current market worth of the allocation.
    quotas_used * redemption.fund_investment.investment_fund.latest_quota_value
  end

  # == gain_loss
  #
  # @category *Finance*
  #
  # Category:: This calculates the result of the investment by comparing current
  #            value to original cost. It shows whether the allocation is in
  #            profit or loss.
  #
  # Attributes:: - *@gain_loss* - returns the difference between current and cost values.
  #
  def gain_loss

    # Explanation:: This ensures both cost and current market value exist. If
    #               either is missing, the gain/loss cannot be computed.
    return nil unless cost_basis && current_market_value

    # Explanation:: This performs the simple subtraction: current value minus
    #               historical cost, yielding gain or loss.
    current_market_value - cost_basis
  end

  # == return_percentage
  #
  # @category *Finance*
  #
  # Category:: This method expresses the gain or loss as a percentage of the
  #            cost, allowing users to compare performance relative to size.
  #
  # Attributes:: - *@return_percentage* - returns the performance ratio in percent.
  #
  def return_percentage

    # Explanation:: This checks that cost_basis exists, gain_loss exists, and
    #               cost_basis is positive to avoid invalid percentage results.
    return nil unless cost_basis && gain_loss && cost_basis > 0

    # Explanation:: This divides gain/loss by cost to get the return ratio, then
    #               multiplies by 100 to convert to a percentage.
    (gain_loss / cost_basis) * 100
  end

  # == holding_period_days
  #
  # @category *Timing*
  #
  # Category:: This method measures how many days the quotas were held between
  #            the original application and the redemption event.
  #
  # Attributes:: - *@holding_period_days* - returns the duration in days.
  #
  def holding_period_days

    # Explanation:: This checks whether both application and redemption dates
    #               exist. Without them, it cannot calculate the period.
    return nil unless application&.request_date && redemption&.request_date

    # Explanation:: This subtracts the two dates and converts the result to an
    #               integer number of days.
    (redemption.request_date - application.request_date).to_i
  end

  private

  # == sufficient_quotas_in_application
  #
  # @category *Validation*
  #
  # Category:: This validation ensures that the application has enough quotas
  #            available to cover the allocation. It prevents overuse.
  #
  # Attributes:: - *@quotas_used* - verified against available quotas.
  #
  def sufficient_quotas_in_application

    # Explanation:: This exits early unless both application and quotas_used are
    #               present. Without them, no validation is needed.
    return unless application && quotas_used

    # Explanation:: This retrieves the application's current available quotas so
    #               the model can compare them to the requested value.
    available_quotas = application.available_quotas

    # Explanation:: If the record already exists, it adds back the previous
    #               quotas_used so updates do not accidentally block valid edits.
    if persisted?
      available_quotas += quotas_used_was.to_d
    end

    # Explanation:: This checks whether quotas_used exceeds availability. If so,
    #               it adds a validation error with a helpful message.
    if quotas_used > available_quotas
      errors.add(:quotas_used, "exceeds available quotas in the application: (#{available_quotas})")
    end
  end

  # == applications_belong_to_same_fund_investment
  #
  # @category *Validation*
  #
  # Category:: This ensures the allocation only links records from the same
  #            **FundInvestment**, preventing mismatched financial sources.
  #
  # Attributes:: - *@application* - validated against redemption’s fund.
  #
  def applications_belong_to_same_fund_investment

    # Explanation:: This exits unless both application and redemption exist,
    #               since both are necessary to compare fund investments.
    return unless application && redemption

    # Explanation:: This checks whether the application’s fund matches the
    #               redemption’s fund. If not, it raises a validation error.
    unless application.fund_investment == redemption.fund_investment
      errors.add(:application, "must belong to the same fund investment as the redemption")
    end
  end

  # == unique_allocation_per_redemption_application
  #
  # @category *Validation*
  #
  # Category:: This validation prevents creating two allocations for the same
  #            redemption + application combination, ensuring consistency.
  #
  # Attributes:: - *@redemption/application* - verified against duplicates.
  #
  def unique_allocation_per_redemption_application

    # Explanation:: This exits unless both redemption and application exist,
    #               because duplicates only matter when both are present.
    return unless redemption && application

    # Explanation:: This looks for an existing allocation with the same
    #               redemption and application, building the base query.
    existing = self.class.where(redemption: redemption, application: application)

    # Explanation:: If the record already exists, it excludes itself to avoid
    #               false positives during updates.
    existing = existing.where.not(id: id) if persisted?

    # Explanation:: This final check adds an error if another record with the
    #               same combination already exists, enforcing uniqueness.
    if existing.exists?
      errors.add(:base, "already has an allocation for this redemption and application")
    end
  end
end