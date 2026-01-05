# === economic_index
#
# @author Moisés Reis
# @added 12/17/2025
# @package *Meta*
# @description This file represents an economic indicator, such as inflation or
#              interest rates, and manages its relationship with the
#              **EconomicIndexHistory** class to track values over time.
# @category *Model*
#
# Usage:: - *[What]* This code acts as a central registry for different types of
#           financial markers used to calculate adjustments or costs.
#         - *[How]* It stores the identity of the index and provides methods to
#           retrieve specific historical values from the database.
#         - *[Why]* It is necessary to provide a standardized way for the app to
#           access financial data needed for contracts and reports.
#
# Attributes:: - *name* @string - the full official name of the economic marker
#              - *abbreviation* @string - a short code used for quick identification
#              - *description* @text - a brief summary explaining what the index tracks
#
class EconomicIndex < ApplicationRecord

  # Explanation:: This creates a connection to multiple history records and
  #               ensures that if an index is deleted, all its past
  #               recorded values are also removed from the system.
  has_many :economic_index_histories, dependent: :destroy

  # Explanation:: This ensures that every index has a unique name and that
  #               the name is long enough to be meaningful for users
  #               browsing the financial lists.
  validates :name, presence: true, uniqueness: {
    case_sensitive: false
  }, length: { minimum: 3, maximum: 100 }

  # Explanation:: This requires a unique short code for the index and checks
  #               that it only contains capital letters or numbers to
  #               keep the data clean and consistent.
  validates :abbreviation, presence: true, uniqueness: { case_sensitive: false }, length: { minimum: 2, maximum: 10 }, format: {
    with: /\A[A-Z0-9]+\z/,
    message: "must be uppercase letters and numbers only"
  }

  # Explanation:: This allows for an optional text description that helps
  #               users understand the purpose of the index, as long
  #               as the text is not excessively long.
  validates :description, length: { maximum: 500 }, allow_blank: true

  # Explanation:: This provides a quick way to filter and find only the
  #               indexes that have received new data updates within
  #               a specific recent timeframe, usually 30 days.
  scope :with_recent_data, ->(days = 30) {
    joins(:economic_index_histories)
      .where(economic_index_histories: { date: days.days.ago..Date.current })
      .distinct
  }

  # == latest_value
  #
  # @author Moisés Reis
  # @category *Data*
  #
  # Category:: This searches through all historical records for this index
  #            and picks out the most recent number available.
  #            It returns nothing if no history exists yet.
  #
  # Attributes:: - *latest_value* - the most recent numerical value found.
  #
  def latest_value
    economic_index_histories.order(date: :desc).first&.value
  end

  # == value_on
  #
  # @author Moisés Reis
  # @category *Data*
  #
  # Category:: This looks for a specific value that was recorded on a
  #            particular day chosen by the user.
  #            It helps in finding precise data for past events.
  #
  # Attributes:: - *date* - the specific calendar day to look up.
  #
  def value_on(date)
    economic_index_histories.find_by(date: date)&.value
  end

  # == values_between
  #
  # @author Moisés Reis
  # @category *Data*
  #
  # Category:: This gathers a list of all recorded values within a specific
  #            time range. It organizes them from the oldest to the
  #            newest so they can be easily displayed in a chart.
  #
  # Attributes:: - *start_date* - the beginning of the time period.
  #              - *end_date* - the conclusion of the time period.
  #
  def values_between(start_date, end_date)
    economic_index_histories.where(date: start_date..end_date).order(:date)
  end

  # == ransackable_attributes
  #
  # @author Moisés Reis
  # @category *Search*
  #
  # Category:: This defines which pieces of information about the index
  #            can be used by the search tool to find specific records.
  #            It acts as a security filter for search queries.
  #
  # Attributes:: - *auth_object* - an optional parameter for user permissions.
  #
  def self.ransackable_attributes(auth_object = nil)
    ["abbreviation", "created_at", "description", "id", "name", "updated_at"]
  end
end