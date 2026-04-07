# frozen_string_literal: true

# == NormalizeHelper
#
# @author Moisés Reis
# @project Meta Investimentos
# @added 04/06/2026
# @package Meta
# @category Helpers
#
# @description
#   Provides a standardized set of methods to format and normalize data for the
#   user interface. It ensures consistent styling for currencies, dates,
#   percentages, and empty states across tables and cards.
#
# @example Formatting a currency value
#   normalize_currency(1250.5)
#   # => <span class="line-clamp-2 font-mono" scope="row">R$1.250,50</span>
#
module NormalizeHelper
  # @return [String] Base CSS classes for table cell elements
  BASE_CLASSES = "line-clamp-2"

  # @return [String] Standard placeholder for missing or null data
  NO_DATA_TEXT = "-"

  # @return [String] Default label for empty card metrics
  NO_CARD_DATA_TEXT = "Sem alteração"

  # == normalize_no_data
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Renders a standardized placeholder for missing data with muted styling.
  #
  # @return [ActiveSupport::SafeBuffer] HTML span element with the "no data" text
  #
  def normalize_no_data
    classes = "#{BASE_CLASSES} !text-muted !font-mono"
    content_tag(:span, NO_DATA_TEXT, class: classes, scope: "row")
  end

  # == normalize_title
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Formats a string as a table title/header with medium font weight.
  #
  # @param title [String, nil] The text to display
  # @return [ActiveSupport::SafeBuffer] Formatted span or "no data" placeholder
  #
  def normalize_title(title)
    return normalize_no_data if title.blank?

    classes = "#{BASE_CLASSES} font-medium"
    content_tag(:span, title, class: classes, scope: "row")
  end

  # == normalize_text
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Formats and truncates general text for display in table rows.
  #
  # @param text [String, nil] The text to normalize
  # @return [ActiveSupport::SafeBuffer] Truncated span or "no data" placeholder
  #
  def normalize_text(text)
    return normalize_no_data if text.blank?

    classes = BASE_CLASSES.to_s
    content_tag(:span, truncate(text, length: 60), class: classes, scope: "row")
  end

  # == normalize_badge
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Renders a colorful badge component. If no type is provided, it assigns
  #   a consistent color based on the content's hash.
  #
  # @param content [String, nil] The text inside the badge
  # @param type [String, nil] Optional specific badge style (e.g., 'success')
  # @return [ActiveSupport::SafeBuffer] HTML badge or "no data" placeholder
  #
  def normalize_badge(content, type = nil)
    return normalize_no_data if content.blank?

    types = %w[inchworm indigo teal primary honeysuckle]
    selected_type = type || types[content.to_s.hash % types.size]

    content_tag(:span, content, class: "badge badge-#{selected_type}")
  end

  # == normalize_currency
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Financial Helper
  #
  # @description
  #   Formats a numeric value into Brazilian Real (BRL) currency format.
  #
  # @param value [Numeric, nil] The amount to format
  # @return [ActiveSupport::SafeBuffer] Formatted currency span
  #
  # @example
  #   normalize_currency(100) # => "R$100,00"
  #
  def normalize_currency(value)
    return normalize_no_data if value.blank? || !valid_nonzero_number?(value)

    classes = "#{BASE_CLASSES} font-mono"
    formatted_money = number_to_currency(value, unit: "R$", separator: ",", delimiter: ".")

    content_tag(:span, formatted_money, class: classes, scope: "row")
  end

  # == normalize_quota
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Financial Helper
  #
  # @description
  #   Formats a numeric value as a high-precision currency (6 decimals),
  #   typically used for investment quotas.
  #
  # @param value [Numeric, nil] The quota value
  # @return [ActiveSupport::SafeBuffer] Formatted quota span
  #
  def normalize_quota(value)
    return normalize_no_data if value.blank? || !valid_nonzero_number?(value)

    classes = "#{BASE_CLASSES} font-mono"
    formatted_money = number_to_currency(
      value,
      unit: "R$",
      separator: ",",
      delimiter: ".",
      precision: 6
    )

    content_tag(:span, formatted_money, class: classes, scope: "row")
  end

  # == normalize_number
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Formats a generic number with 2 decimal places and Brazilian separators.
  #
  # @param value [Numeric, nil] The number to format
  # @return [ActiveSupport::SafeBuffer] Formatted numeric span
  #
  def normalize_number(value)
    return normalize_no_data if value.blank? || !valid_nonzero_number?(value)

    classes = "#{BASE_CLASSES} font-mono"
    formatted_number = number_with_precision(
      value,
      precision: 2,
      delimiter: ".",
      separator: ",",
      strip_insignificant_zeros: true
    )

    content_tag(:span, formatted_number, class: classes, scope: "row")
  end

  # == normalize_fk
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Formats a foreign key or ID reference as a small outlined badge.
  #
  # @param value [Object, nil] The reference value
  # @return [ActiveSupport::SafeBuffer] Formatted badge span
  #
  def normalize_fk(value)
    return normalize_no_data if value.blank?

    classes = "#{BASE_CLASSES} badge badge-outline !text-2xs"
    content_tag(:span, value, class: classes, scope: "row")
  end

  # == normalize_code
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Formats an identification code using a monospaced font.
  #
  # @param value [String, nil] The code string
  # @return [ActiveSupport::SafeBuffer] Formatted code span
  #
  def normalize_code(value)
    return normalize_no_data if value.blank?

    classes = "#{BASE_CLASSES} font-mono"
    content_tag(:span, value, class: classes, scope: "row")
  end

  # == normalize_percentage
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Formats a numeric value as a percentage with a specific precision.
  #
  # @param value [Numeric, nil] The percentage value
  # @param precision [Integer] Number of decimal places (default: 2)
  # @return [ActiveSupport::SafeBuffer] Formatted percentage span
  #
  def normalize_percentage(value, precision: 2)
    return normalize_no_data if value.blank?

    classes = "#{BASE_CLASSES} font-mono"
    truncated_value = value.to_d.truncate(precision)
    formatted_percentage = number_to_percentage(truncated_value, precision: precision, separator: ",", delimiter: ".")

    content_tag(:span, formatted_percentage, class: classes, scope: "row")
  end

  # == normalize_date
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Formats a date or time object into the Brazilian DD/MM/YYYY sequence.
  #
  # @param value [Date, Time, nil] The date object
  # @return [ActiveSupport::SafeBuffer] Formatted date span
  #
  def normalize_date(value)
    return normalize_no_data if value.blank?

    classes = "#{BASE_CLASSES} font-mono"
    formatted_date = value.to_date.strftime("%d/%m/%Y")

    content_tag(:span, formatted_date, class: classes, scope: "row")
  end

  # == normalize_trend
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Renders a value with a directional icon (up/down/stale) and semantic coloring.
  #
  # @param value [Numeric, nil] The change value to evaluate
  # @param format [Symbol] Output format: :currency or :percentage (default: :currency)
  # @return [ActiveSupport::SafeBuffer] Flex container with icon and formatted value
  #
  def normalize_trend(value, format: :currency)
    return normalize_no_data if value.blank?

    trend = value > 0 ? :up : (value < 0 ? :down : :stale)

    styles = {
      up: { color: "text-success-600 [&>span]:!text-success-600", icon: "trending-up" },
      down: { color: "text-danger-600 [&>span]:!text-danger-600", icon: "trending-down" },
      stale: { color: "text-muted [&>svg]:hidden", icon: "minus" }
    }[trend]

    formatted_value = format == :percentage ? normalize_percentage(value.abs) : normalize_currency(value.abs)

    content_tag(:div, class: "flex items-center [&>span]:!font-medium gap-1 #{styles[:color]}") do
      concat inline_svg_tag("icons/#{styles[:icon]}.svg", class: "w-4 h-4 fill-current")
      concat formatted_value
    end
  end

  # == normalize_latest_date
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Retrieves and formats the date from the most recent record in a collection.
  #
  # @param collection [ActiveRecord::Relation] The collection to search
  # @param attribute [Symbol] The date attribute to sort by (default: :date)
  # @return [ActiveSupport::SafeBuffer] Formatted date span or placeholder
  #
  def normalize_latest_date(collection, attribute: :date)
    latest_record = collection.order(attribute => :desc).first
    return normalize_no_data if latest_record.blank? || latest_record.send(attribute).blank?

    normalize_date(latest_record.send(attribute))
  end

  # == normalize_boolean
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Converts a boolean condition into a success or danger badge with custom text.
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

  # == normalize_card_percentage
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Formats a numeric percentage for display inside a card metric.
  #
  # @param value [Numeric, nil] The percentage value
  # @param precision [Integer] Number of decimal places (default: 2)
  # @param zero_label [String] Text to show if value is zero (default: NO_CARD_DATA_TEXT)
  # @return [String] Formatted percentage string
  #
  def normalize_card_percentage(value, precision: 2, zero_label: NO_CARD_DATA_TEXT)
    return zero_label unless value.respond_to?(:to_f)
    return zero_label if value.to_f.zero?

    formatted = value.to_f.round(precision)
    precision.zero? ? "#{formatted.to_i}%" : "#{formatted}%"
  end

  # == normalize_card_text
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Formats a card metric text with optional prefixes for positive/negative numbers.
  #
  # @param value [Object, nil] The value to display
  # @param zero_label [String] Label for zero or nil (default: NO_CARD_DATA_TEXT)
  # @param positive_prefix [String] Prefix for positive values (default: "+")
  # @param negative_prefix [String] Prefix for negative values (default: "")
  # @return [String] Formatted string
  #
  def normalize_card_text(value, zero_label: NO_CARD_DATA_TEXT, positive_prefix: "+", negative_prefix: "")
    return zero_label if value.nil?
    return zero_label if value.respond_to?(:zero?) && value.zero?
    return value.to_s unless value.respond_to?(:positive?) && value.respond_to?(:negative?)

    value.positive? ? "#{positive_prefix}#{value}" : "#{negative_prefix}#{value}"
  end

  # == normalize_card_time_ago
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Generates a "Time ago" string for card timestamps.
  #
  # @param value [Time, Date, nil] The timestamp
  # @param zero_label [String] Label for missing or future dates (default: NO_CARD_DATA_TEXT)
  # @return [String] Human-readable distance in words (e.g., "Há 5 minutos atrás")
  #
  def normalize_card_time_ago(value, zero_label: NO_CARD_DATA_TEXT)
    return zero_label if value.blank?
    return zero_label unless value.respond_to?(:to_time)

    time = value.to_time
    return zero_label if time.future?

    "Há #{time_ago_in_words(time)} atrás"
  end

  # == normalize_card_boolean
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Converts boolean values into specific labels for card displays.
  #
  # @param value [Boolean, nil] The value to evaluate
  # @param labels [Hash] Custom mapping for :true/:positive and :false/:negative
  # @param zero_label [String] Label for nil (default: NO_CARD_DATA_TEXT)
  # @return [String] The resolved label string
  #
  def normalize_card_boolean(value, labels: {}, zero_label: NO_CARD_DATA_TEXT)
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

  # == normalize_card_time_since
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Generates a "Since [time] ago" string for card timelines.
  #
  # @param value [Time, Date, nil] The start timestamp
  # @param zero_label [String] Label for missing or future dates (default: NO_CARD_DATA_TEXT)
  # @return [String] Human-readable distance in words (e.g., "Desde 2 dias atrás")
  #
  def normalize_card_time_since(value, zero_label: NO_CARD_DATA_TEXT)
    return zero_label if value.blank?
    return zero_label unless value.respond_to?(:to_time)

    time = value.to_time
    return zero_label if time.future?

    "Desde #{time_ago_in_words(time)} atrás"
  end

  # == normalize_card_currency
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Financial Helper
  #
  # @description
  #   Placeholder for future card-specific currency normalization logic.
  #
  def normalize_card_currency; end
end
