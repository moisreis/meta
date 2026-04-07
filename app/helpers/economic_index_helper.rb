# frozen_string_literal: true

# == EconomicIndexHelper
#
# @author Moisés Reis
# @project Meta Investimentos
# @added 06/04/2026
# @package Meta
# @category Helpers
#
# @description
#   Provides utility methods for processing and displaying economic index data.
#   It handles historical record retrieval, statistical calculations, and
#   formatting data for charts and visualizations.
#
# @example Usage in a view
#   economic_index_latest_value(@index)
#   # => 12.75
#
module EconomicIndexHelper
  # == economic_index_latest_value
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Retrieves the most recent value stored for a specific economic index.
  #
  # @param economic_index [EconomicIndex] The economic index record
  # @return [Numeric, nil] The latest value or nil if none exists
  #
  def economic_index_latest_value(economic_index)
    economic_index.latest_value
  end

  # == economic_index_first_record
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Retrieves the oldest historical record available for the index based on date.
  #
  # @param economic_index [EconomicIndex] The economic index record
  # @return [EconomicIndexHistory, nil] The first history record or nil
  #
  def economic_index_first_record(economic_index)
    economic_index.economic_index_histories.order(date: :asc).first
  end

  # == economic_index_last_record
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Retrieves the most recent historical record available for the index.
  #
  # @param economic_index [EconomicIndex] The economic index record
  # @return [EconomicIndexHistory, nil] The last history record or nil
  #
  def economic_index_last_record(economic_index)
    economic_index.economic_index_histories.order(date: :desc).first
  end

  # == economic_index_records_count
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Returns the total number of historical data points available for the index.
  #
  # @param economic_index [EconomicIndex] The economic index record
  # @return [Integer] The count of history records
  #
  def economic_index_records_count(economic_index)
    economic_index.economic_index_histories.count
  end

  # == economic_index_twelve_month_history
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Builds a dataset of index values from the last twelve months, formatted
  #   specifically for chart labels (Month/Year).
  #
  # @param economic_index [EconomicIndex] The economic index record
  # @return [Hash] A hash mapping "Mon/YY" strings to their respective values
  #
  # @example
  #   economic_index_twelve_month_history(index)
  #   # => { "Jan/24" => 10.5, "Feb/24" => 10.7 }
  #
  def economic_index_twelve_month_history(economic_index)
    economic_index.economic_index_histories
                  .where("date >= ?", 12.months.ago)
                  .order(date: :asc)
                  .pluck(:date, :value)
                  .map { |date, value| [date.strftime("%b/%y"), value] }
                  .to_h
  end

  # == economic_index_thirty_day_history
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Builds a dataset of index values from the last thirty days, formatted
  #   for daily chart visualizations.
  #
  # @param economic_index [EconomicIndex] The economic index record
  # @return [Hash] A hash mapping "DD/MM" strings to their respective values
  #
  def economic_index_thirty_day_history(economic_index)
    economic_index.economic_index_histories
                  .where("date >= ?", 30.days.ago)
                  .order(date: :asc)
                  .pluck(:date, :value)
                  .map { |date, value| [date.strftime("%d/%m"), value] }
                  .to_h
  end

  # == economic_index_avg_value
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Calculates the arithmetic mean of all historical values for the index.
  #
  # @param economic_index [EconomicIndex] The economic index record
  # @return [Numeric, nil] The average value or nil if no records exist
  #
  def economic_index_avg_value(economic_index)
    all_values = economic_index.economic_index_histories.pluck(:value)
    return nil if all_values.empty?

    all_values.sum / all_values.size
  end

  # == economic_index_min_value
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Identifies the lowest historical value ever recorded for the index.
  #
  # @param economic_index [EconomicIndex] The economic index record
  # @return [Numeric, nil] The minimum value or nil
  #
  def economic_index_min_value(economic_index)
    economic_index.economic_index_histories.pluck(:value).min
  end

  # == economic_index_max_value
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Identifies the highest historical value ever recorded for the index.
  #
  # @param economic_index [EconomicIndex] The economic index record
  # @return [Numeric, nil] The maximum value or nil
  #
  def economic_index_max_value(economic_index)
    economic_index.economic_index_histories.pluck(:value).max
  end

  # == economic_index_avg_12_months
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Calculates the arithmetic mean of index values specifically within the
  #   last twelve months.
  #
  # @param economic_index [EconomicIndex] The economic index record
  # @return [Numeric, nil] The 12-month average or nil
  #
  def economic_index_avg_12_months(economic_index)
    last_12_months = economic_index.economic_index_histories
                                   .where("date >= ?", 12.months.ago)
                                   .pluck(:value)
    return nil if last_12_months.empty?

    last_12_months.sum / last_12_months.size
  end

  # == economic_index_related_articles
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Finds normative articles that reference the economic index by searching
  #   for its abbreviation in descriptions and bodies.
  #
  # @param economic_index [EconomicIndex] The economic index record
  # @return [ActiveRecord::Relation] Articles mentioning the index abbreviation
  #
  def economic_index_related_articles(economic_index)
    NormativeArticle.where(
      "description ILIKE ? OR article_body ILIKE ?",
      "%#{economic_index.abbreviation}%",
      "%#{economic_index.abbreviation}%"
    )
  end

  # == economic_index_recent_values
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Retrieves a collection of the most recent historical values for list displays.
  #
  # @param economic_index [EconomicIndex] The economic index record
  # @param limit [Integer] Number of records to return (default: 15)
  # @return [ActiveRecord::Relation] Collection of recent history records
  #
  def economic_index_recent_values(economic_index, limit: 15)
    economic_index.economic_index_histories.order(date: :desc).limit(limit)
  end

  # == economic_index_statistics
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Aggregates all statistical metrics for the index into a single hash object.
  #
  # @param economic_index [EconomicIndex] The economic index record
  # @return [Hash] Contains latest, average, min, max, and 12-month average values
  #
  # @see #economic_index_latest_value
  # @see #economic_index_avg_value
  #
  def economic_index_statistics(economic_index)
    {
      latest_value: economic_index_latest_value(economic_index),
      avg_value: economic_index_avg_value(economic_index),
      min_value: economic_index_min_value(economic_index),
      max_value: economic_index_max_value(economic_index),
      avg_12_months: economic_index_avg_12_months(economic_index)
    }
  end

  # == economic_index_chart_data
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Consolidates various historical datasets optimized for chart rendering components.
  #
  # @param economic_index [EconomicIndex] The economic index record
  # @return [Hash] Contains 12-month and 30-day history datasets
  #
  # @see #economic_index_twelve_month_history
  # @see #economic_index_thirty_day_history
  #
  def economic_index_chart_data(economic_index)
    {
      twelve_months: economic_index_twelve_month_history(economic_index),
      thirty_days: economic_index_thirty_day_history(economic_index)
    }
  end

  # == economic_index_metadata
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Collects general metadata and audit dates for the index and its history.
  #
  # @param economic_index [EconomicIndex] The economic index record
  # @return [Hash] Contains counts, boundary dates, and creation timestamp
  #
  def economic_index_metadata(economic_index)
    first = economic_index_first_record(economic_index)
    last = economic_index_last_record(economic_index)

    {
      records_count: economic_index_records_count(economic_index),
      first_record_date: first&.date,
      last_record_date: last&.date,
      created_at: economic_index.created_at
    }
  end

  # == economic_index_value_change
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Calculates the percentage variation between a given history record and
  #   the record immediately preceding it in time.
  #
  # @param economic_index [EconomicIndex] The economic index record
  # @param value [EconomicIndexHistory] The specific history record to evaluate
  # @return [Numeric, nil] The percentage variation or nil if no previous record exists
  #
  # @example
  #   economic_index_value_change(index, history_record)
  #   # => 2.5 (represents 2.5% increase)
  #
  def economic_index_value_change(economic_index, value)
    previous = economic_index.economic_index_histories
                             .where("date < ?", value.date)
                             .order(date: :desc)
                             .first

    return nil unless previous&.value

    ((value.value - previous.value) / previous.value * 100)
  end
end
