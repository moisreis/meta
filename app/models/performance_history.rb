# === performance_history
#
# @author Moisés Reis
# @added 12/4/2025
# @package *Meta*
# @description This class stores historical return data for a specific financial product
#              within a user's **Portfolio**. It calculates and tracks monthly, annual,
#              and rolling 12-month returns for an investment.
# @category *Model*
#
# Usage:: - *[What]* This code block tracks the time-weighted performance of a **FundInvestment**
#           within a specific **Portfolio** over discrete time periods.
#         - *[How]* It links to both the **Portfolio** and the **FundInvestment** records, and uses
#           custom validations to ensure the investment is actually held by the portfolio.
#         - *[Why]* The application requires this historical data to generate charts, calculate
#           annualized metrics, and provide users with a complete performance timeline.
#
# Attributes:: - *portfolio_id* @integer - The unique identifier of the **Portfolio** this performance record belongs to.
#              - *fund_investment_id* @integer - The unique identifier of the **FundInvestment** record that generated this return.
#              - *period* @date - The end date of the period for which the returns were calculated (usually the end of a month).
#              - *monthly_return* @decimal - The calculated return for the single period (e.g., one month).
#              - *yearly_return* @decimal - The cumulative return since the beginning of the current calendar year.
#              - *last_12_months_return* @decimal - The rolling cumulative return over the past 12 months.
#'
class PerformanceHistory < ApplicationRecord

  # Explanation:: This establishes a many-to-one relationship, linking this record
  #               to the specific **Portfolio** that owns the investment being tracked.
  belongs_to :portfolio

  # Explanation:: This establishes a many-to-one relationship, linking this record
  #               to the specific **FundInvestment** record for which performance is tracked.
  belongs_to :fund_investment

  # Explanation:: This validation ensures that the link to the parent **Portfolio**
  #               is always present and cannot be blank when saving the record.
  validates :portfolio_id, presence: true

  # Explanation:: This validation ensures that the link to the **FundInvestment** record
  #               is always present and cannot be blank when saving the record.
  validates :fund_investment_id, presence: true

  # Explanation:: This validation ensures that the period for which the returns
  #               are calculated is always present and cannot be blank.
  validates :period, presence: true

  # Explanation:: This validation ensures that the monthly return is a valid number,
  #               but it allows the field to be nil if the calculation has not been performed yet.
  validates :monthly_return, numericality: true, allow_nil: true

  # Explanation:: This validation ensures that the yearly return is a valid number,
  #               but it allows the field to be nil if the calculation has not been performed yet.
  validates :yearly_return, numericality: true, allow_nil: true

  # Explanation:: This validation ensures that the 12-month return is a valid number,
  #               but it allows the field to be nil if the calculation has not been performed yet.
  validates :last_12_months_return, numericality: true, allow_nil: true

  # Explanation:: This validation guarantees that a unique performance record exists
  #               for a specific combination of **Portfolio**, **FundInvestment**, and time period.
  validates :period, uniqueness: {
    scope: [:portfolio_id, :fund_investment_id],
    message: "there is already a performance record for this portfolio, fund investment, and period"
  }

  # Explanation:: This is a custom validation that checks if the associated **FundInvestment**
  #               is actually an investment belonging to the specified **Portfolio** before saving.
  validate :fund_investment_belongs_to_portfolio

  # Explanation:: This is a custom validation that prevents performance records
  #               from being created for dates that have not yet occurred.
  validate :period_not_in_future

  # Explanation:: This defines a query scope that easily retrieves all performance history
  #               records that belong to a specified **Portfolio** object.
  scope :for_portfolio, ->(portfolio) { where(portfolio: portfolio) }

  # Explanation:: This defines a query scope that easily retrieves all performance history
  #               records associated with a specified **FundInvestment** object.
  scope :for_fund_investment, ->(investment) { where(fund_investment: investment) }

  # Explanation:: This defines a query scope that retrieves all records where the **period**
  #               falls inclusively between the provided start and end dates.
  scope :in_period_range, ->(start_period, end_period) { where(period: start_period..end_period) }

  # Explanation:: This defines a query scope that retrieves records for the last 12 months,
  #               allowing for an optional number of months to be specified.
  scope :recent, ->(months = 12) { where(period: months.months.ago..Date.current) }

  # Explanation:: This defines a query scope that orders the records sequentially
  #               by the **period** date, ensuring a chronological view.
  scope :by_period, -> { order(:period) }

  # Explanation:: This defines a query scope that only retrieves records where
  #               at least one of the return metrics (**monthly_return**, etc.) is positive.
  scope :positive_returns, -> { where('monthly_return > 0 OR yearly_return > 0 OR last_12_months_return > 0') }

  # == identifier
  #
  # @author Moisés Reis
  # @category *Display*
  #
  # Display:: This method creates a human-readable string that uniquely identifies this performance record.
  #           It combines the **Portfolio** name, the **InvestmentFund** name, and the specific time period.
  #
  def identifier
    portfolio_name = portfolio&.name || "Unknown Portfolio"
    fund_name = fund_investment&.investment_fund&.fund_name || "Unknown Fund"
    period_str = period&.strftime('%Y-%m') || "Unknown Period"

    "#{portfolio_name} / #{fund_name} (#{period_str})"
  end

  # == best_return_period
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Calculation:: This method determines which of the three calculated returns (monthly, yearly, or 12-month)
  #               has the highest value for this specific period record. It returns the name of that period.
  #
  def best_return_period
    returns = {
      monthly: monthly_return,
      yearly: yearly_return,
      twelve_months: last_12_months_return
    }.compact

    return nil if returns.empty?

    returns.max_by { |_, value| value }.first
  end

  # == best_return_value
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Calculation:: This method retrieves the actual numerical value of the highest return
  #               among the monthly, yearly, and 12-month metrics for this period.
  #
  def best_return_value
    best_period = best_return_period
    return nil unless best_period

    case best_period
    when :monthly then monthly_return
    when :yearly then yearly_return
    when :twelve_months then last_12_months_return
    end
  end

  # == positive_performance?
  #
  # @author Moisés Reis
  # @category *Query*
  #
  # Query:: This method checks if any of the three main return metrics (monthly, yearly, or 12-month)
  #         is greater than zero for this record, indicating positive performance in some capacity.
  #
  def positive_performance?
    [monthly_return, yearly_return, last_12_months_return].any? { |ret| ret&.positive? }
  end

  # == negative_performance?
  #
  # @author Moisés Reis
  # @category *Query*
  #
  # Query:: This method checks if any of the three main return metrics (monthly, yearly, or 12-month)
  #         is less than zero for this record, indicating negative performance in some capacity.
  #
  def negative_performance?
    [monthly_return, yearly_return, last_12_months_return].any? { |ret| ret&.negative? }
  end

  # == performance_summary
  #
  # @author Moisés Reis
  # @category *Aggregation*
  #
  # Aggregation:: This method compiles all the performance metrics and calculation results
  #               from the record into a single, organized hash for easy data consumption.
  #
  def performance_summary
    {
      period: period,
      monthly_return: monthly_return,
      yearly_return: yearly_return,
      last_12_months_return: last_12_months_return,
      best_return_period: best_return_period,
      best_return_value: best_return_value,
      positive_performance: positive_performance?
    }
  end

  # == market_value
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Calculation:: This method calculates the market value at the end of the period
  #               by adding the initial balance (invested value) to the earnings for that period.
  #
  def market_value
    return BigDecimal('0') unless initial_balance && earnings
    initial_balance + earnings
  end

  # == invested_value
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Calculation:: This method returns the invested value (initial balance) for the period.
  #               This represents the value invested at the start of the period.
  #
  def invested_value
    initial_balance || BigDecimal('0')
  end

  private

  # == fund_investment_belongs_to_portfolio
  #
  # @author Moisés Reis
  # @category *Validation*
  #
  # Validation:: This private method ensures that the **FundInvestment** record being tracked
  #              is actually linked to the **Portfolio** specified in this performance history.
  #
  def fund_investment_belongs_to_portfolio
    return unless portfolio && fund_investment

    unless fund_investment.portfolio == portfolio
      errors.add(:fund_investment, "must belong to the specified portfolio")
    end
  end

  # == period_not_in_future
  #
  # @author Moisés Reis
  # @category *Validation*
  #
  # Validation:: This private method checks the **period** date to guarantee that the performance
  #              history record is not being created for a date that is in the future.
  #
  def period_not_in_future
    return unless period

    if period > Date.current
      errors.add(:period, "cannot be in the future")
    end
  end
end