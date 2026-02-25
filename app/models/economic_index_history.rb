# === economic_index_history
#
# @author Moisés Reis
# @added 12/18/2025
# @package *Meta*
# @description This file tracks the specific numerical values of an index on
#              different dates, linking each entry back to its parent
#              **EconomicIndex** to build a historical timeline.
# @category *Model*
#
# Usage:: - *[What]* This code stores a single point of data, like a specific
#           percentage or price, recorded at a specific moment in time.
#         - *[How]* It connects to an index, validates that the date is logical,
#           and provides tools to compare values against previous records.
#         - *[Why]* It allows the application to perform financial calculations
#           over time, such as measuring inflation growth or interest trends.
#
# Attributes:: - *date* @date - the specific day this financial value was recorded
#              - *value* @decimal - the actual number or rate of the index on that day
#              - *economic_index_id* @integer - the ID linking this to its main index
#
class EconomicIndexHistory < ApplicationRecord

  # Explanation:: This establishes a direct link to the **EconomicIndex**
  #               model, indicating that this specific record belongs
  #               to a larger category of financial markers.
  belongs_to :economic_index

  # Explanation:: This ensures that every entry has a valid calendar date
  #               assigned to it, so the system knows exactly when
  #               this specific value occurred.
  validates :date, presence: true

  # Explanation:: This requires that every historical entry is attached
  #               to an existing index, preventing "orphan" data
  #               that doesn't belong to any specific category.
  validates :economic_index_id, presence: true

  # Explanation:: This checks that the value is not only present but
  #               is also a valid number, which is necessary for
  #               performing mathematical calculations later.
  validates :value, presence: true, numericality: true

  # Explanation:: This prevents the system from having two different
  #               values for the same index on the same day,
  #               ensuring the data remains accurate and clear.
  validates :date, uniqueness: {
    scope: :economic_index_id,
    message: "este índice já possui um valor registrado para esta data."
  }

  # Explanation:: This is a custom check that prevents users from
  #               entering financial data for dates that haven't
  #               happened yet, keeping the database realistic.
  validate :date_not_in_future

  # Explanation:: This provides a quick way to filter the database
  #               to show only the history records that belong
  #               to one specific economic index.
  scope :for_index, ->(index) { where(economic_index: index) }

  # Explanation:: This helps find all records that fall between
  #               two specific dates, which is useful for
  #               generating reports or drawing period charts.
  scope :in_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }

  # Explanation:: This quickly fetches data from the most recent
  #               period, usually the last 30 days, to show
  #               the latest trends in the application.
  scope :recent, ->(days = 30) { where(date: days.days.ago..Date.current) }

  # Explanation:: This automatically organizes the history entries
  #               starting from the oldest date up to the newest,
  #               making the timeline easy to follow.
  scope :by_date, -> { order(:date) }

  # == identifier
  #
  # @author Moisés Reis
  # @category *Labeling*
  #
  # Category:: This creates a simple text label that combines the
  #            index name and the date. It makes the record
  #            easy for a person to identify at a glance.
  #
  # Attributes:: - *@identifier* - a string combining the name and date.
  #
  def identifier
    index_name = economic_index&.abbreviation || "Unknown Index"
    "#{index_name} on #{date.strftime('%Y-%m-%d')}"
  end

  # == change_from_previous
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Category:: This finds the record that came immediately before
  #            this one and calculates the difference in
  #            their values to show how much it moved.
  #
  # Attributes:: - *@change_from_previous* - the subtraction result of two values.
  #
  def change_from_previous
    previous_record = self.class.for_index(economic_index)
                          .where('date < ?', date)
                          .order(date: :desc)
                          .first

    return nil unless previous_record

    value - previous_record.value
  end

  # == percentage_change_from_previous
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Category:: This calculates the growth or decline as a
  #            percentage compared to the previous record,
  #            helping users see the rate of change.
  #
  # Attributes:: - *@percentage_change_from_previous* - the percentage of growth.
  #
  def percentage_change_from_previous
    previous_record = self.class.for_index(economic_index)
                          .where('date < ?', date)
                          .order(date: :desc)
                          .first

    return nil unless previous_record&.value&.nonzero?

    ((value - previous_record.value) / previous_record.value) * 100
  end

  # == annualized_return
  #
  # @author Moisés Reis
  # @category *Finance*
  #
  # Category:: This estimates what the growth would be over
  #            a full year based on the current data trend
  #            using the formula: $R = ((\frac{V_{f}}{V_{i}})^{1/p} - 1) \times 100$.
  #
  # Attributes:: - *@days* - the time period used for the projection.
  #
  def annualized_return(days = 252)
    start_record = self.class.for_index(economic_index)
                       .where('date <= ?', date - days.days)
                       .order(date: :desc)
                       .first

    return nil unless start_record&.value&.positive?

    periods = days.to_f / 365
    return nil if periods <= 0

    ((value / start_record.value) ** (1 / periods) - 1) * 100
  end

  private

  # == date_not_in_future
  #
  # @author Moisés Reis
  # @category *Validation*
  #
  # Category:: This helper method checks if the date entered
  #            is ahead of today's date. If it is, it adds
  #            an error message to prevent saving.
  #
  # Attributes:: - *@date* - the user-provided date to be verified.
  #
  def date_not_in_future
    return unless date

    if date > Date.current
      errors.add(:date, "cannot be in the future")
    end
  end

  # == ransackable_attributes
  #
  # @author Moisés Reis
  # @category *Search*
  #
  # Category:: This lists the specific details of a history record,
  #            like its value or date, that the search system
  #            is allowed to look through for users.
  #
  # Attributes:: - *@auth_object* - optional user permissions for search.
  #
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "date", "economic_index_id", "id", "updated_at", "value"]
  end

  # == ransackable_associations
  #
  # @author Moisés Reis
  # @category *Search*
  #
  # Category:: This tells the search system that it is allowed to
  #            dig into the related **EconomicIndex** to find
  #            history records based on the index name.
  #
  # Attributes:: - *@auth_object* - optional user permissions for relationships.
  #
  def self.ransackable_associations(auth_object = nil)
    ["economic_index"]
  end
end