# === fund_valuation
#
# @author Moisés Reis
# @added 12/19/2025
# @package *Meta*
# @description This file records the daily price and financial data for
#              specific investment funds stored in the **InvestmentFund** class.
# @category *Model*
#
# Usage:: - *[What]* This code stores the daily value of a fund's share
#           and tracks how much it grows or shrinks over time.
#         - *[How]* It uses the date and the fund's registration number to
#           save the share price and compare it with previous days.
#         - *[Why]* It is necessary so the application can show investors
#           their profit history and the current worth of their money.
#
# Attributes:: - *date* @Date - the specific day this valuation was recorded
#              - *fund_cnpj* @String - the unique ID number of the fund
#              - *quota_value* @Decimal - the monetary price of a single share
#              - *source* @String - where the information was originally found
#              - *other_public_information* @Text - extra details about the fund
#
class FundValuation < ApplicationRecord

  # Explanation:: This line tells the system to use both the date and the
  #               fund's ID together as the unique key for each record.
  #               It prevents saving two different values for the same fund on the same day.
  self.primary_key = [:date, :fund_cnpj]

  # Explanation:: This creates a connection to the **InvestmentFund** file.
  #               It allows the system to fetch the full name and details
  #               of the fund using the registration number provided.
  belongs_to :investment_fund, foreign_key: :fund_cnpj, primary_key: :cnpj

  # Explanation:: This rule ensures that every valuation record must
  #               include a valid date before it can be saved.
  #               It prevents records with missing calendar information.
  validates :date, presence: true

  # Explanation:: This checks that the fund's ID number is present and
  #               follows the official national format for business IDs.
  #               It keeps the data clean and recognizable by the system.
  validates :fund_cnpj, presence: true, format: {
    with: /\A\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}\z/,
    message: "must be in the format XX.XXX.XXX/XXXX-XX"
  }

  # Explanation:: This ensures that the share price is always a number
  #               greater than zero when we save a new valuation.
  #               It stops the system from recording negative or empty values.
  validates :quota_value, presence: true, numericality: { greater_than: 0 }

  # Explanation:: This limits the name of the data source to 100 characters.
  #               It ensures the information stays brief and fits
  #               neatly within the application's database limits.
  validates :source, length: { maximum: 100 }, allow_blank: true

  # Explanation:: This allows for a long description of extra public info
  #               while setting a maximum limit to save storage space.
  #               It provides a place for details that don't fit in other fields.
  validates :other_public_information, length: { maximum: 2000 }, allow_blank: true

  # Explanation:: This runs a custom check to make sure the valuation
  #               date is not set to a day that has not happened yet.
  #               It maintains the logic that we only value things in the past or today.
  validate :date_not_in_future

  # Explanation:: This is a shortcut that lets the system quickly find
  #               all valuation records belonging to one specific fund.
  #               It makes searching through thousands of records very fast.
  scope :for_fund, ->(cnpj) { where(fund_cnpj: cnpj) }

  # Explanation:: This helps the application filter and show values that
  #               fall between two specific dates chosen by the user.
  #               It is commonly used to generate monthly or yearly reports.
  scope :in_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }

  # Explanation:: This automatically retrieves valuation data from the
  #               last 30 days to show the most current performance.
  #               It keeps the user's view focused on recent financial changes.
  scope :recent, ->(days = 30) { where(date: days.days.ago..Date.current) }

  # Explanation:: This organizes the list of valuations in order of time.
  #               It ensures that graphs and lists start from the oldest
  #               date and move toward the most recent.
  scope :by_date, -> { order(:date) }

  # == identifier
  #
  # @author Moisés Reis
  # @category *Format*
  #
  # Category:: This creates a simple label that combines the fund ID and
  #            the date into one readable line of text.
  #            It helps humans identify exactly which record they are looking at.
  #
  # Attributes:: - *none* - this method uses existing data to return a string.
  #
  def identifier
    "#{fund_cnpj} on #{date.strftime('%Y-%m-%d')}"
  end

  # == daily_change
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Category:: This calculates the difference in money between today's
  #            price and the price recorded on the previous day.
  #            It shows if the fund gained or lost value in dollars.
  #
  # Attributes:: - *none* - it looks up the previous record in the database.
  #
  def daily_change

    # Explanation:: This line looks through the database to find the
    #               single most recent record before the current date.
    #               It allows the system to compare two days of data.
    previous_day_data = self.class.for_fund(fund_cnpj)
                            .where('date < ?', date)
                            .order(date: :desc)
                            .first

    return nil unless previous_day_data

    quota_value - previous_day_data.quota_value
  end

  # == daily_change_percentage
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Category:: This calculates the percentage of growth or loss compared
  #            to the previous day's value.
  #            It helps users understand the performance speed of their investment.
  #
  # Attributes:: - *none* - it compares the current value to the previous one.
  #
  def daily_change_percentage
    previous_day_data = self.class.for_fund(fund_cnpj)
                            .where('date < ?', date)
                            .order(date: :desc)
                            .first

    return nil unless previous_day_data&.quota_value&.positive?

    ((quota_value - previous_day_data.quota_value) / previous_day_data.quota_value) * 100
  end

  private

  # == date_not_in_future
  #
  # @author Moisés Reis
  # @category *Validation*
  #
  # Category:: This checks if the date entered is actually in the future.
  #            If it is, the system adds an error message to the record.
  #
  # Attributes:: - *none* - it compares the record's date to today's date.
  #
  def date_not_in_future
    return unless date

    if date > Date.current
      errors.add(:date, "cannot be in the future")
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "date", "fund_cnpj", "other_public_information", "quota_value", "source", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["investment_fund"]
  end
end