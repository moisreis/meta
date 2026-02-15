module NormalizeHelper

  BASE_CLASSES = "line-clamp-2"

  NO_DATA_TEXT = "-"

  def normalize_no_data
    # Explanation:: This line retrieves the shared styling for text elements.
    #               It ensures the "no data" message matches the size and
    #               alignment of all other information in the table rows.
    classes = "#{BASE_CLASSES} !text-muted !font-mono"

    # Explanation:: This line produces the final HTML for the empty state.
    #               It uses the predefined source of truth for the text
    #               to keep the language uniform across the entire app.
    content_tag(:span, NO_DATA_TEXT, class: classes, scope: "row")
  end

  def normalize_title(title)
    # Explanation:: This line checks if the title exists and has content.
    #               If the text is missing, it automatically displays the
    #               standardized "no data" message instead of an empty space.
    return normalize_no_data if title.blank?

    # Explanation:: This line defines the visual design for the table header.
    #               It combines shared alignment with bold font and spacing
    #               to create a prominent label that stands out to the user.
    classes = "#{BASE_CLASSES} font-medium"

    # Explanation:: This line generates the HTML element for the table cell.
    #               It combines the content and the styles to create a
    #               finished component that the browser can display.
    content_tag(:span, title, class: classes, scope: "row")
  end

  def normalize_text(text)
    # Explanation:: This line detects if the provided information is empty.
    #               If no data is found, it triggers the automatic message
    #               to inform the user that the information is unavailable.
    return normalize_no_data if text.blank?

    # Explanation:: This variable builds the styling list for regular text.
    #               It uses the base alignment rules and adds specific
    #               colors and sizes to differentiate it from headers.
    classes = "#{BASE_CLASSES}"

    # Explanation:: This line creates the final visual container for the text.
    #               It turns the raw data into a safe HTML element that
    #               appears correctly inside your application's tables.
    content_tag(:span, truncate(text, length: 60), class: classes, scope: "row")
  end

  def normalize_badge(content, type = nil)
    # Explanation:: This line ensures that the badge is only drawn if there
    #               is actual content. If the value is empty, it uses the
    #               general placeholder so the interface remains uniform.
    return normalize_no_data if content.blank?

    # Explanation:: This line defines the available color themes for the badges.
    #               It provides a set of design tokens that the system can
    #               rotate through to distinguish between different values.
    types = %w[inchworm indigo teal primary honeysuckle]

    # Explanation:: This logic selects a color based on the content's unique ID.
    #               By using a mathematical hash, it ensures that the same
    #               word always receives the same color every time it appears.
    selected_type = type || types[content.to_s.hash % types.size]

    # Explanation:: This line builds the final HTML tag for the badge component.
    #               It combines the calculated type with the badge styles
    #               to create a consistent and colorful visual indicator.
    content_tag(:span, content, class: "badge badge-#{selected_type}")
  end

  def normalize_currency(value)
    # Explanation:: This line verifies if a valid number was provided.
    #               If the value is empty or missing, it automatically
    #               shows the standard label for unavailable data.
    return normalize_no_data if value.blank? || !valid_nonzero_number?(value)

    # Explanation:: This variable defines the alignment and look of the price.
    #               It centers the currency and applies the base text rules
    #               to keep financial data organized within the table.
    classes = "#{BASE_CLASSES} font-mono"

    # Explanation:: This line transforms the raw number into a BRL string.
    #               It adds the R$ symbol and uses commas for decimals to
    #               comply with Brazilian financial formatting standards.
    formatted_money = number_to_currency(value, unit: "R$", separator: ",", delimiter: ".")

    # Explanation:: This line creates the final HTML tag for the currency.
    #               It wraps the formatted price in a span with the defined
    #               styles so it aligns perfectly with other table rows.
    content_tag(:span, formatted_money, class: classes, scope: "row")
  end

  def normalize_number(value)
    # Explanation:: This line checks if the number is present and valid.
    #               If the value is missing, it triggers the automatic
    #               placeholder to avoid showing an empty or confusing gap.
    return normalize_no_data if value.blank? || !valid_nonzero_number?(value)

    # Explanation:: This variable sets the typography for the number.
    #               It uses a monospaced font so that every digit occupies
    #               the same width, which is ideal for technical data.
    classes = "#{BASE_CLASSES} font-mono"

    # Explanation:: This line adds delimiters to separate thousands and millions.
    #               It uses a dot as the separator to follow the standard
    #               Brazilian pattern for displaying large numeric values.
    formatted_number = number_with_delimiter(value, delimiter: ".")

    # Explanation:: This line creates the final container for the number.
    #               It combines the data with the specific font styles
    #               to ensure the value is readable and professionally presented.
    content_tag(:span, formatted_number, class: classes, scope: "row")
  end

  def normalize_fk(value)

    return normalize_no_data if value.blank?

    classes = "#{BASE_CLASSES} badge badge-outline !text-2xs"

    content_tag(:span, value, class: classes, scope: "row")
  end

  def normalize_code(value)
    return normalize_no_data if value.blank?

    classes = "#{BASE_CLASSES} font-mono"

    content_tag(:span, value, class: classes, scope: "row")
  end

  def normalize_percentage(value)
    # Explanation:: This line checks if the percentage value is available.
    #               If the input is empty, it displays the standard message
    #               for missing data to keep the table rows consistent.
    return normalize_no_data if value.blank?

    # Explanation:: This variable sets the alignment and font for the data.
    #               It uses monospaced text so that the percentage symbols
    #               and digits align neatly across different rows.
    classes = "#{BASE_CLASSES} font-mono"

    # Explanation:: This line formats the number with a percent sign.
    #               It uses a comma as the decimal separator and ensures
    #               the value follows the local mathematical notation.
    formatted_percentage = number_to_percentage(value, precision: 2, separator: ",", delimiter: ".")

    # Explanation:: This line produces the final HTML tag for the view.
    #               It wraps the formatted percentage in a span that
    #               aligns with the design of other numeric columns.
    content_tag(:span, formatted_percentage, class: classes, scope: "row")
  end

  def normalize_date(value)
    # Explanation:: This line verifies if a valid date has been provided.
    #               If the record has no date, it automatically triggers
    #               the standard placeholder to keep the timeline consistent.
    return normalize_no_data if value.blank?

    # Explanation:: This variable defines the visual style for the date text.
    #               It uses monospaced font and base alignment to ensure
    #               that columns of dates remain perfectly aligned and tidy.
    classes = "#{BASE_CLASSES} font-mono"

    # Explanation:: This line converts the date object into a readable string.
    #               It uses the Brazilian sequence of day, month, and year
    #               separated by slashes for a familiar and clear appearance.
    formatted_date = value.to_date.strftime("%d/%m/%Y")

    # Explanation:: This line creates the final visual container for the date.
    #               It wraps the formatted string in a span that integrates
    #               seamlessly with the rest of your application's tables.
    content_tag(:span, formatted_date, class: classes, scope: "row")
  end

  def normalize_trend(value, format: :currency)
    # Explanation:: This line ensures the method only runs if a value exists.
    #               If the data is missing, it falls back to the standard
    #               "SEM DADOS" message to maintain a clean interface.
    return normalize_no_data if value.blank?

    # Explanation:: This logic identifies the direction of the numeric change.
    #               It categorizes the value as positive, negative, or neutral
    #               to determine which colors and icons to apply.
    trend = value > 0 ? :up : (value < 0 ? :down : :stale)

    # Explanation:: This mapping defines the visual identity for each trend.
    #               It links specific Tailwind colors to movement types,
    #               ensuring the icon and text always share the same hue.
    styles = {
      up: { color: "text-success-600 [&>span]:!text-success-600", icon: "trending-up" },
      down: { color: "text-danger-600 [&>span]:!text-danger-600", icon: "trending-down" },
      stale: { color: "text-muted", icon: "minus" }
    }[trend]

    # Explanation:: This logic chooses the correct formatting method to use.
    #               It delegates the number processing to either the currency
    #               or percentage helper based on the provided format attribute.
    formatted_value = format == :percentage ? normalize_percentage(value.abs) : normalize_currency(value.abs)

    # Explanation:: This block generates the final HTML component for the view.
    #               It groups the icon and text in a flex container, applying
    #               the chosen color to both elements simultaneously.
    content_tag(:div, class: "flex items-center [&>span]:!font-medium gap-1 #{styles[:color]}") do
      concat inline_svg_tag("icons/#{styles[:icon]}.svg", class: "w-4 h-4 fill-current")
      concat formatted_value
    end
  end

  def normalize_latest_date(collection, attribute: :date)
    # Explanation:: This line retrieves the most recent record from the set.
    #               It orders the items by the chosen date attribute in
    #               descending order to extract the latest available entry.
    latest_record = collection.order(attribute => :desc).first

    # Explanation:: This condition checks if the record and its date exist.
    #               If the collection is empty, it returns the standard
    #               missing data placeholder to keep the table consistent.
    return normalize_no_data if latest_record.blank? || latest_record.send(attribute).blank?

    # Explanation:: This call delegates the formatting to the standard date helper.
    #               It ensures the result uses the Brazilian format and
    #               monospaced font for a professional, aligned appearance.
    normalize_date(latest_record.send(attribute))
  end

  def normalize_boolean(condition, true_text, false_text)
    # Explanation:: This line determines which label and color to use.
    #               It checks the condition to pick the success style for
    #               truthy values and the danger style for falsy ones.
    status = condition ? { text: true_text, type: "success" } : { text: false_text, type: "danger" }

    # Explanation:: This call utilizes the standard badge helper for rendering.
    #               It passes the selected text and the specific color type
    #               to ensure the badge follows the application's UI standards.
    normalize_badge(status[:text], status[:type])
  end

  NO_CARD_DATA_TEXT = "Sem alteração"

  def normalize_card_percentage(value, precision: 2, zero_label: NO_CARD_DATA_TEXT)
    return zero_label unless value.respond_to?(:to_f)
    return zero_label if value.to_f.zero?

    formatted = value.to_f.round(precision)
    precision.zero? ? "#{formatted.to_i}%" : "#{formatted}%"
  end

  def normalize_card_text(value, zero_label: NO_CARD_DATA_TEXT, positive_prefix: "+", negative_prefix: "")
    return zero_label if value.nil?
    return zero_label if value.respond_to?(:zero?) && value.zero?
    return value.to_s unless value.respond_to?(:positive?) && value.respond_to?(:negative?)

    value.positive? ? "#{positive_prefix}#{value}" : "#{negative_prefix}#{value}"
  end

  def normalize_card_time_ago(value, zero_label: NO_CARD_DATA_TEXT)
    return zero_label if value.blank?
    return zero_label unless value.respond_to?(:to_time)

    time = value.to_time
    return zero_label if time.future?

    "Há #{time_ago_in_words(time)} atrás"
  end

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

  def normalize_card_time_since(value, zero_label: NO_CARD_DATA_TEXT)
    return zero_label if value.blank?
    return zero_label unless value.respond_to?(:to_time)

    time = value.to_time
    return zero_label if time.future?

    "Desde #{time_ago_in_words(time)} atrás"
  end

  def normalize_card_currency

  end
end