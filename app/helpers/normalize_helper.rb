# frozen_string_literal: true

# == NormalizeHelper
#
# @author Moisés Reis
# @project Meta Investimentos
# @added 04/06/2026
# @updated 04/28/2026 (refactored to use Ui presenters)
# @package Meta
# @category Helpers
#
# @description
#   Provides a standardized set of helper methods that delegate to specialized UI presenters
#   for formatting and normalizing data. Ensures consistent styling for currencies, dates,
#   percentages, and empty states across tables and cards throughout the application.
#
#   This helper acts as a facade to the Ui presenter layer, simplifying view code and
#   maintaining a single point of configuration for UI formatting rules.
#
# @see Ui::TextPresenter For text normalization
# @see Ui::FinancialPresenter For currency and numeric formatting
# @see Ui::BadgePresenter For badge rendering
# @see Ui::DatePresenter For date formatting
# @see Ui::MetricPresenter For metric calculations
#
# @example Formatting a currency value
#   normalize_currency(1250.5)
#   # => <span class="line-clamp-2 font-mono">R$1.250,50</span>
#
# TABLE OF CONTENTS:
#   1.  Text Formatting
#       1a. normalize_no_data
#       1b. normalize_title
#       1c. normalize_text
#   2.  Financial Formatting
#       2a. normalize_currency
#       2b. normalize_quota
#       2c. normalize_number
#       2d. normalize_percentage
#   3.  Badge & Code Formatting
#       3a. normalize_badge
#       3b. normalize_code
#       3c. normalize_fk
#   4.  Date Formatting
#       4a. normalize_date
#       4b. normalize_latest_date
#   5.  Trend & Boolean Formatting
#       5a. normalize_trend
#       5b. normalize_boolean
#   6.  Card Formatting
#       6a. normalize_card_percentage
#       6b. normalize_card_text
#       6c. normalize_card_time_ago
#       6d. normalize_card_boolean
#       6e. normalize_card_time_since
#       6f. normalize_card_currency
#
module NormalizeHelper
  # =============================================================
  #                    1. TEXT FORMATTING
  # =============================================================

  # =============================================================
  #                   1a. normalize_no_data
  # =============================================================

  # Renders a standardized placeholder for missing data with muted styling.
  #
  # @return [ActiveSupport::SafeBuffer] HTML span element with the "no data" text
  #
  def normalize_no_data
    Ui::EmptyStatePresenter.new(self).render
  end

  # =============================================================
  #                    1b. normalize_title
  # =============================================================

  # Formats a string as a table title/header with medium font weight.
  #
  # @param title [String, nil] The text to display
  # @return [ActiveSupport::SafeBuffer] Formatted span or "no data" placeholder
  #
  def normalize_title(title)
    Ui::TextPresenter.new(self).title(title)
  end

  # =============================================================
  #                    1c. normalize_text
  # =============================================================

  # Formats and truncates general text for display in table rows.
  #
  # @param text [String, nil] The text to normalize
  # @return [ActiveSupport::SafeBuffer] Truncated span or "no data" placeholder
  #
  def normalize_text(text)
    Ui::TextPresenter.new(self).text(text)
  end

  # =============================================================
  #                 2. FINANCIAL FORMATTING
  # =============================================================

  # =============================================================
  #                 2a. normalize_currency
  # =============================================================

  # Formats a numeric value into Brazilian Real (BRL) currency format.
  #
  # @param value [Numeric, nil] The amount to format
  # @return [ActiveSupport::SafeBuffer] Formatted currency span
  #
  def normalize_currency(value)
    Ui::FinancialPresenter.new(self).currency(value)
  end

  # =============================================================
  #                   2b. normalize_quota
  # =============================================================

  # Formats a numeric value as a high-precision currency (6 decimals),
  # typically used for investment quotas.
  #
  # @param value [Numeric, nil] The quota value
  # @return [ActiveSupport::SafeBuffer] Formatted quota span
  #
  def normalize_quota(value)
    Ui::FinancialPresenter.new(self).quota(value)
  end

  # =============================================================
  #                    2c. normalize_number
  # =============================================================

  # Formats a generic number with 2 decimal places and Brazilian separators.
  #
  # @param value [Numeric, nil] The number to format
  # @return [ActiveSupport::SafeBuffer] Formatted numeric span
  #
  def normalize_number(value)
    Ui::FinancialPresenter.new(self).number(value)
  end

  # =============================================================
  #                  2d. normalize_percentage
  # =============================================================

  # Formats a numeric value as a percentage with a specific precision.
  #
  # @param value [Numeric, nil] The percentage value
  # @param precision [Integer] Number of decimal places (default: 2)
  # @return [ActiveSupport::SafeBuffer] Formatted percentage span
  #
  def normalize_percentage(value, precision: 2)
    Ui::FinancialPresenter.new(self).percentage(value, precision: precision)
  end

  # =============================================================
  #              3. BADGE & CODE FORMATTING
  # =============================================================

  # =============================================================
  #                   3a. normalize_badge
  # =============================================================

  # Renders a colorful badge component. If no type is provided, it assigns
  # a consistent color based on the content's hash.
  #
  # @param content [String, nil] The text inside the badge
  # @param type [String, nil] Optional specific badge style (e.g., 'success')
  # @return [ActiveSupport::SafeBuffer] HTML badge or "no data" placeholder
  #
  def normalize_badge(content, type = nil)
    Ui::BadgePresenter.new(self).render(content, type: type)
  end

  # =============================================================
  #                    3b. normalize_code
  # =============================================================

  # Formats an identification code using a monospaced font.
  #
  # @param value [String, nil] The code string
  # @return [ActiveSupport::SafeBuffer] Formatted code span
  #
  def normalize_code(value)
    Ui::CodePresenter.new(self).render(value)
  end

  # =============================================================
  #                     3c. normalize_fk
  # =============================================================

  # Formats a foreign key or ID reference as a small outlined badge.
  #
  # @param value [Object, nil] The reference value
  # @return [ActiveSupport::SafeBuffer] Formatted badge span
  #
  def normalize_fk(value)
    Ui::FkPresenter.new(self).render(value)
  end

  # =============================================================
  #                 4. DATE FORMATTING
  # =============================================================

  # =============================================================
  #                   4a. normalize_date
  # =============================================================

  # Formats a date or time object into the Brazilian DD/MM/YYYY sequence.
  #
  # @param value [Date, Time, nil] The date object
  # @return [ActiveSupport::SafeBuffer] Formatted date span
  #
  def normalize_date(value)
    Ui::DatePresenter.new(self).date(value)
  end

  # =============================================================
  #                 4b. normalize_latest_date
  # =============================================================

  # Retrieves and formats the date from the most recent record in a collection.
  #
  # @param collection [ActiveRecord::Relation] The collection to search
  # @param attribute [Symbol] The date attribute to sort by (default: :date)
  # @return [ActiveSupport::SafeBuffer] Formatted date span or placeholder
  #
  def normalize_latest_date(collection, attribute: :date)
    Ui::DatePresenter.new(self).latest_date(collection, attribute: attribute)
  end

  # =============================================================
  #            5. TREND & BOOLEAN FORMATTING
  # =============================================================

  # =============================================================
  #                   5a. normalize_trend
  # =============================================================

  # Renders a value with a directional icon (up/down/stale) and semantic coloring.
  #
  # @param value [Numeric, nil] The change value to evaluate
  # @param format [Symbol] Output format: :currency or :percentage (default: :currency)
  # @return [ActiveSupport::SafeBuffer] Flex container with icon and formatted value
  #
  def normalize_trend(value, format: :currency)
    Ui::TrendPresenter.new(self).render(value, format: format)
  end

  # =============================================================
  #                  5b. normalize_boolean
  # =============================================================

  # Converts a boolean condition into a success or danger badge with custom text.
  #
  # @param condition [Boolean] The condition to evaluate
  # @param true_text [String] Text for the success state
  # @param false_text [String] Text for the danger state
  # @return [ActiveSupport::SafeBuffer] HTML badge
  #
  def normalize_boolean(condition, true_text, false_text)
    status = condition ? { text: true_text, type: "success" } : { text: false_text, type: "danger" }
    normalize_badge(status[:text], status[:type])
  end

def normalize_boolean_label(value, labels: {}, zero_label: "-")
  Ui::StatePresenter.new(self).boolean_label(
    value,
    labels: labels,
    zero_label: zero_label
  )
end

def normalize_status(value, positive:, negative:, default: :default)
  Ui::StatePresenter.new(self).boolean_status(
    value,
    positive: positive,
    negative: negative,
    default: default
  )
end

  # =============================================================
  #                 6. CARD FORMATTING
  # =============================================================

  # =============================================================
  #              6a. normalize_card_percentage
  # =============================================================

  # Formats a numeric percentage for display inside a card metric.
  #
  # @param value [Numeric, nil] The percentage value
  # @param precision [Integer] Number of decimal places (default: 2)
  # @param zero_label [String] Text to show if value is zero (default: "-")
  # @return [String] Formatted percentage string
  #
  def normalize_card_percentage(value, precision: 2, zero_label: "-")
    return zero_label unless value.respond_to?(:to_f)
    return zero_label if value.to_f.zero?

    formatted = value.to_f.round(precision)
    precision.zero? ? "#{formatted.to_i}%" : "#{formatted}%"
  end

  # =============================================================
  #                 6b. normalize_card_text
  # =============================================================

  # Formats a card metric text with optional prefixes for positive/negative numbers.
  #
  # @param value [Object, nil] The value to display
  # @param zero_label [String] Label for zero or nil (default: "-")
  # @param positive_prefix [String] Prefix for positive values (default: "+")
  # @param negative_prefix [String] Prefix for negative values (default: "")
  # @return [String] Formatted string
  #
  def normalize_card_text(value, zero_label: "-", positive_prefix: "+", negative_prefix: "")
    return zero_label if value.nil?
    return zero_label if value.respond_to?(:zero?) && value.zero?
    return value.to_s unless value.respond_to?(:positive?) && value.respond_to?(:negative?)

    value.positive? ? "#{positive_prefix}#{value}" : "#{negative_prefix}#{value}"
  end

  # =============================================================
  #               6c. normalize_card_time_ago
  # =============================================================

  # Generates a "Time ago" string for card timestamps.
  #
  # @param value [Time, Date, nil] The timestamp
  # @param zero_label [String] Label for missing or future dates (default: "-")
  # @return [String] Human-readable distance in words (e.g., "Há 5 minutos atrás")
  #
  def normalize_card_time_ago(value, zero_label: "-")
    return zero_label if value.blank?
    return zero_label unless value.respond_to?(:to_time)

    time = value.to_time
    return zero_label if time.future?

    "Há #{time_ago_in_words(time)} atrás"
  end


  # =============================================================
  #              6d. normalize_card_boolean
  # =============================================================

  # Converts boolean values into specific labels for card displays.
  #
  # @param value [Boolean, nil] The value to evaluate
  # @param labels [Hash] Custom mapping for :true/:positive and :false/:negative
  # @param zero_label [String] Label for nil (default: "-")
  # @return [String] The resolved label string
  #
  def normalize_card_boolean(value, labels: {}, zero_label: "-")
    return zero_label if value.nil?

    case value
    when true
      labels.fetch(:true, labels.fetch(:positive, "Sim"))
    when false
      labels.fetch(:false, labels.fetch(:negative, "Não"))
    else
      zero_label
    end
  end

  # =============================================================
  #               6e. normalize_card_time_since
  # =============================================================

  # Generates a "Since [time] ago" string for card timelines.
  #
  # @param value [Time, Date, nil] The start timestamp
  # @param zero_label [String] Label for missing or future dates (default: "-")
  # @return [String] Human-readable distance in words (e.g., "Desde 2 dias atrás")
  #
  def normalize_card_time_since(value, zero_label: "-")
    return zero_label if value.blank?
    return zero_label unless value.respond_to?(:to_time)

    time = value.to_time
    return zero_label if time.future?

    "Desde #{time_ago_in_words(time)} atrás"
  end

  # =============================================================
  #              6f. normalize_card_currency
  # =============================================================

  # Placeholder for future card-specific currency normalization logic.
  #
  # @return [void]
  #
  def normalize_card_currency
    # Placeholder for future implementation
  end
end
