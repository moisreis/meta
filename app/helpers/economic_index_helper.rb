# frozen_string_literal: true

module EconomicIndexHelper
  # Returns the most recent value for the economic index
  #
  # @param economic_index [EconomicIndex] the economic index record
  # @return [Numeric, nil] latest value or nil
  def economic_index_latest_value(economic_index)
    economic_index.latest_value
  end

  # Returns the first historical record
  #
  # @param economic_index [EconomicIndex] the economic index record
  # @return [EconomicIndexHistory, nil] first record or nil
  def economic_index_first_record(economic_index)
    economic_index.economic_index_histories.order(date: :asc).first
  end

  # Returns the most recent historical record
  #
  # @param economic_index [EconomicIndex] the economic index record
  # @return [EconomicIndexHistory, nil] last record or nil
  def economic_index_last_record(economic_index)
    economic_index.economic_index_histories.order(date: :desc).first
  end

  # Returns count of historical records
  #
  # @param economic_index [EconomicIndex] the economic index record
  # @return [Integer] count of history records
  def economic_index_records_count(economic_index)
    economic_index.economic_index_histories.count
  end

  # Builds twelve month history data for charts
  #
  # @param economic_index [EconomicIndex] the economic index record
  # @return [Hash] hash mapping formatted dates to values
  def economic_index_twelve_month_history(economic_index)
    economic_index.economic_index_histories
                  .where("date >= ?", 12.months.ago)
                  .order(date: :asc)
                  .pluck(:date, :value)
                  .map { |date, value| [date.strftime("%b/%y"), value] }
                  .to_h
  end

  # Builds thirty day history data for charts
  #
  # @param economic_index [EconomicIndex] the economic index record
  # @return [Hash] hash mapping formatted dates to values
  def economic_index_thirty_day_history(economic_index)
    economic_index.economic_index_histories
                  .where("date >= ?", 30.days.ago)
                  .order(date: :asc)
                  .pluck(:date, :value)
                  .map { |date, value| [date.strftime("%d/%m"), value] }
                  .to_h
  end

  # Calculates historical average value
  #
  # @param economic_index [EconomicIndex] the economic index record
  # @return [Numeric, nil] average value or nil
  def economic_index_avg_value(economic_index)
    all_values = economic_index.economic_index_histories.pluck(:value)
    return nil unless all_values.present?

    all_values.sum / all_values.size
  end

  # Returns minimum historical value
  #
  # @param economic_index [EconomicIndex] the economic index record
  # @return [Numeric, nil] minimum value or nil
  def economic_index_min_value(economic_index)
    economic_index.economic_index_histories.pluck(:value).min
  end

  # Returns maximum historical value
  #
  # @param economic_index [EconomicIndex] the economic index record
  # @return [Numeric, nil] maximum value or nil
  def economic_index_max_value(economic_index)
    economic_index.economic_index_histories.pluck(:value).max
  end

  # Calculates average for last 12 months
  #
  # @param economic_index [EconomicIndex] the economic index record
  # @return [Numeric, nil] 12-month average or nil
  def economic_index_avg_12_months(economic_index)
    last_12_months = economic_index.economic_index_histories
                                   .where("date >= ?", 12.months.ago)
                                   .pluck(:value)
    return nil unless last_12_months.present?

    last_12_months.sum / last_12_months.size
  end

  # Finds normative articles that reference this index
  #
  # @param economic_index [EconomicIndex] the economic index record
  # @return [ActiveRecord::Relation] articles mentioning the index
  def economic_index_related_articles(economic_index)
    NormativeArticle.where(
      "description ILIKE ? OR article_body ILIKE ?",
      "%#{economic_index.abbreviation}%",
      "%#{economic_index.abbreviation}%"
    )
  end

  # Returns recent historical values
  #
  # @param economic_index [EconomicIndex] the economic index record
  # @param limit [Integer] number of records to return (default: 15)
  # @return [ActiveRecord::Relation] recent history records
  def economic_index_recent_values(economic_index, limit: 15)
    economic_index.economic_index_histories.order(date: :desc).limit(limit)
  end

  # Returns all statistical metrics
  #
  # @param economic_index [EconomicIndex] the economic index record
  # @return [Hash] hash with all statistical metrics
  def economic_index_statistics(economic_index)
    {
      latest_value: economic_index_latest_value(economic_index),
      avg_value: economic_index_avg_value(economic_index),
      min_value: economic_index_min_value(economic_index),
      max_value: economic_index_max_value(economic_index),
      avg_12_months: economic_index_avg_12_months(economic_index)
    }
  end

  # Returns chart data for visualizations
  #
  # @param economic_index [EconomicIndex] the economic index record
  # @return [Hash] hash with chart datasets
  def economic_index_chart_data(economic_index)
    {
      twelve_months: economic_index_twelve_month_history(economic_index),
      thirty_days: economic_index_thirty_day_history(economic_index)
    }
  end

  # Returns metadata about the index
  #
  # @param economic_index [EconomicIndex] the economic index record
  # @return [Hash] hash with metadata
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

  # Calculates percentage change for a history value
  #
  # @param economic_index [EconomicIndex] the economic index record
  # @param value [EconomicIndexHistory] the history record
  # @return [Numeric, nil] percentage change or nil
  def economic_index_value_change(economic_index, value)
    previous = economic_index.economic_index_histories
                             .where("date < ?", value.date)
                             .order(date: :desc)
                             .first

    return nil unless previous&.value

    ((value.value - previous.value) / previous.value * 100)
  end
end
