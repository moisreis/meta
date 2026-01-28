# === application_helper
#
# @author Moisés Reis
# @added 11/25/2025
# @package *Meta*
# @description This file contains utility methods that assist **Views** and other components
#              in presenting data consistently and managing global application logic.
#              The explanations are in the present simple tense.
# @category *Helper*
#
# Usage:: - *[What]* This code block stores small, reusable functions that simplify the HTML templates,
#           such as formatting numbers or generating UI elements.
#         - *[How]* It defines methods that take data as input, process it
#           (e.g., format a date, calculate a class name), and return the final output for the view.
#         - *[Why]* It keeps the **Views** clean by preventing repeated logic and
#           ensuring a consistent user experience across the entire application.
#
module ApplicationHelper

  # == full_title
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This method constructs the full page title for the browser tab.
  #        It combines a specific page title with the base application name.
  #
  # Attributes:: - *page_title* @string - The specific title of the current page (e.g., "User Profile").
  #
  def full_title(page_title)

    # Explanation:: This defines the base name of the application, used if no specific
    #               page title is provided.
    base_title = "Financial Portfolio Manager"

    # Explanation:: This checks if the `page_title` argument is empty. If it is,
    #               it returns only the base title.
    if page_title.blank?
      base_title
    else

      # Explanation:: If a page title is provided, it combines the specific title
      #               with the base title, separated by a pipe character `|`.
      "#{page_title} | #{base_title}"
    end
  end

  # == currency_format
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This method formats numerical data into a standard Brazilian currency string (R$).
  #        It improves readability by adding the currency symbol, comma, and two decimal places.
  #
  # Attributes:: - *amount* @numeric - The number value to be formatted (e.g., 1234.56).
  #
  def currency_format(amount)

    # Explanation:: This uses the built-in Rails number formatting utility to convert
    #               the raw number into a currency string formatted for the Brazilian locale.
    number_to_currency(
      amount,
      unit: "R$",
      separator: ",",
      delimiter: ".",
      locale: :pt
    )
  end

  # == flash_class_for
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This method maps Rails flash message types (like `notice` or `alert`) to corresponding CSS classes.
  #        It ensures that success messages look green, error messages look red, and so on.
  #
  # Attributes:: - *flash_type* @symbol - The type of flash message (e.g., `:notice`, `:alert`, `:error`).
  #
  def flash_class_for(flash_type)
    # Explanation:: This converts the symbol type into a string key and uses a `case`
    #               statement to return the appropriate Bootstrap-compatible CSS class name.
    case flash_type.to_s
    when "success", "notice"
      "badge-success"
    when "error", "alert"
      "badge-danger"
    when "warning"
      "badge-warning"
    when "info"
      "badge-info"
    else
      # Explanation:: This provides a default class for any message types that are not
      #               specifically mapped above.
      flash_type.to_s
    end
  end

  # == sortable
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This method generates an HTML link that makes a table column sortable using **Ransack** parameters.
  #        It automatically switches the sort direction (ascending/descending) and updates the visual icon.
  #
  # Attributes:: - *name* @string - The display name for the column header (e.g., "Fund Name").
  #             - *column* @symbol - The database column name to sort by (e.g., `:fund_name`).
  #             - *custom_icon* @string - The filename of the SVG icon to display next to the name.
  #
  def sortable(name, column, custom_icon)

    # Explanation:: This retrieves the current sort key from the web address parameters,
    #               specifically looking for the **Ransack** sort parameter, which is often under `params[:q][:s]`.
    current_sort_key = params.dig(
      :q,
      :s
    )

    # Explanation:: This separates the current sort key (e.g., "cnpj desc") into the column
    #               name (`current_column`) and the direction (`current_direction`), defaulting to "asc" if no sort is active.
    current_column, current_direction = current_sort_key&.split || [nil, "asc"]

    # Explanation:: This determines the next sort direction. If the user clicks the currently
    #               sorted column, the direction flips; otherwise, it defaults to ascending ("asc").
    direction =
      if current_column == column.to_s
        current_direction == "asc" ? "desc" : "asc"
      else
        "asc"
      end

    # Explanation:: This constructs the new **Ransack** sort string (e.g., "fund_name desc")
    #               that will be placed in the web address when the link is clicked.
    new_sort = "#{column} #{direction}"

    # Explanation:: This determines which arrow icon to display based on the current sort state:
    #               an upward arrow for ascending, a downward arrow for descending, or a default arrow if the column is not sorted.
    icon =
      if current_column != column.to_s
        "arrow-down"
      elsif current_direction == "asc"
        "arrow-up"
      else
        "arrow-down"
      end

    # Explanation:: This generates the final HTML link, merging the new sort parameter into the
    #               existing web address parameters and wrapping the custom icon, column name, and arrow icon inside it.
    link_to params.permit!.merge(q: (params[:q] || {}).merge(s: new_sort)) do
      content_tag(:div, class: "flex flex-row gap-1 items-center") do
        safe_join([
                    inline_svg_tag("icons/#{custom_icon}.svg", class: "size-6 bg-numerical-100 stroke-numerical-900 rounded-base p-1.5"),
                    name,
                    inline_svg_tag("icons/#{icon}.svg", class: "size-3 stroke-body")
                  ])
      end
    end
  end

  # Explanation:: Defines a fixed list of numeric shade levels used to
  #               determine how strong the color intensity should be.
  #               Freezing prevents accidental modifications.
  SHADE_STEPS = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900].freeze

  # == shade_for_value
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: Calculates a shade level based on how large the value is.
  #        Converts the number into a proportional color intensity
  #        that becomes stronger with higher values.
  #
  def shade_for_value(value, max_value: 100_000)

    # Explanation:: Returns the lowest shade when the value is zero or
    #               negative to avoid unnecessary calculations.
    return 50 if value.to_f <= 0

    # Explanation:: Ensures the value does not exceed the allowed limit.
    #               This keeps the ratio calculation within safe bounds.
    v = [value.to_f, max_value].min

    # Explanation:: Converts the capped value into a 0–1 scale so it can
    #               be mapped proportionally to the shade list.
    ratio = v / max_value

    # Explanation:: Calculates which shade index best represents the ratio.
    #               Rounds to the nearest available shade step.
    index = (ratio * (SHADE_STEPS.size - 1)).round

    # Explanation:: Returns the chosen shade based on the computed index.
    #               This shade is later used to build the CSS class.
    SHADE_STEPS[index]
  end

  # == colored_currency
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: Displays a currency amount with a background color that
  #        becomes darker for larger values. Helps users visually
  #        compare monetary figures at a glance.
  #
  def colored_currency(value, additional_class = "")

    # Explanation:: Returns a neutral placeholder when the value is blank or zero.
    #               Prevents meaningless values from being styled or displayed.
    return content_tag(:span, "N/A", class: "text-muted") unless value.present? && value.to_f != 0

    # Explanation:: Determines how intense the color should be for the value.
    #               Uses shade_for_value to pick the correct shade step.
    shade = shade_for_value(value)

    # Explanation:: Builds the HTML span showing the formatted currency and
    #               applies a class that encodes the chosen shade level.
    content_tag(
      :span,
      number_to_currency(value, unit: "R$ ", separator: ",", delimiter: "."),
      class: "shade px-2 py-0.5 inline-flex items-center justify-center gap-1 whitespace-nowrap rounded-base uppercase font-mono text-sm font-medium currency-shade-#{shade} #{additional_class}"
    )
  end

  # == colored_numerical
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: Displays a numerical amount with a background color that
  #        becomes darker for larger values. Helps users visually
  #        compare numerical figures at a glance.
  #
  def colored_numerical(value, additional_class = "")

    # Explanation:: Returns a neutral placeholder when the value is blank or zero.
    #               Prevents meaningless values from being styled or displayed.
    return content_tag(:span, "N/A", class: "text-muted") unless value.present? && value.to_f != 0

    # Explanation:: Determines how intense the color should be for the value.
    #               Uses shade_for_value to pick the correct shade step.
    shade = shade_for_value(value)

    # Explanation:: Limits the precision of the numerical value
    value = number_with_precision(value, precision: 1)

    # Explanation:: Builds the HTML span showing the formatted numerical and
    #               applies a class that encodes the chosen shade level.
    content_tag(
      :span,
      value,
      class: "shade px-2 py-0.5 inline-flex items-center justify-center gap-1 whitespace-nowrap rounded-base uppercase font-mono text-sm font-medium numerical-shade-#{shade} #{additional_class}"
    )
  end

  # == colored_percentage
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: Displays a percentage amount with a background color that
  #        becomes darker for larger values. Helps users visually
  #        compare percentage figures at a glance.
  #
  def colored_percentage(value, additional_class = "")

    # Explanation:: Returns a neutral placeholder when the value is blank or zero.
    #               Prevents meaningless values from being styled or displayed.
    return content_tag(:span, "N/A", class: "text-muted") unless value.present? && value.to_f != 0

    # Explanation:: Determines how intense the color should be for the value.
    #               Uses shade_for_value to pick the correct shade step.
    shade = shade_for_value(value, max_value: 100)

    # Explanation:: Limits the precision of the numerical value
    value = number_with_precision(value, precision: 1)

    # Explanation:: Builds the HTML span showing the formatted percentage and
    #               applies a class that encodes the chosen shade level.
    content_tag(
      :span,
      "#{value}%",
      class: "shade px-2 py-0.5 inline-flex items-center justify-center gap-1 whitespace-nowrap rounded-base uppercase font-mono text-sm font-medium percentage-shade-#{shade} #{additional_class}"
    )
  end

  # == formatted_timestamp
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: Formats a date and time into a readable string and wraps it
  #        in a styled HTML element. Presents timestamps consistently
  #        across the interface for better readability.
  #
  def formatted_timestamp(datetime, formatter: ->(t) { t.strftime("%d/%m/%Y") })

    # Explanation:: Returns a placeholder when the datetime value is missing.
    #               Prevents errors and keeps the visual layout stable.
    return content_tag(:span, "N/A", class: "font-mono text-muted") unless datetime.present?

    # Explanation:: Uses the formatter to turn the datetime into a formatted
    #               string. Allows injecting alternative formatting logic.
    formatted = formatter.call(datetime)

    # Explanation:: Builds a span containing the formatted date string and
    #               applies a consistent monospaced style for alignment.
    content_tag(:span, formatted, class: "font-mono")
  end

  # == standard_currency
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: Displays a currency amount with a standard pattern.
  #
  def standard_currency(value, additional_class = "")

    # Explanation:: Builds the HTML span showing the formatted currency.
    content_tag(
      :span,
      number_to_currency(value, unit: "R$ ", separator: ",", delimiter: "."),
      class: "font-mono #{additional_class}"
    )
  end

  # == crud_nav_for
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This method generates the full navigation group structure for a given model, including a header and a list of links for key actions.
  #        It is used to create a dedicated section in the sidebar menu for a resource (like portfolios or funds).
  #
  # Attributes:: - *model_class* @Class - The resource class (e.g., `InvestmentFund`) used to find names and paths.
  #             - *singular* @string - The display name for the single item (optional).
  #             - *plural* @string - The display name for the collection of items (optional).
  #             - *icons* @Hash - A hash to override default SVG icons for `index`, `new`, and `reports` links.
  #
  def crud_nav_for(model_class, singular: nil, plural: nil, icons: {})
    singular ||= model_class.model_name.human
    plural ||= model_class.model_name.human(count: 2)
    resources = model_class.model_name.route_key
    count = model_class.count

    default_icons = {
      index: "wallet.svg",
      new: "plus.svg",
      reports: "file-text.svg"
    }

    icon_set = default_icons.merge(icons.symbolize_keys)

    items = [
      {
        icon: icon_set[:index],
        text: "Visualizar".html_safe,
        path: url_for(controller: "/#{resources}", action: :index)
      },
      {
        icon: icon_set[:new],
        text: "Adicionar",
        path: url_for(controller: "/#{resources}", action: :new)
      },
    # {
    #   icon: icon_set[:reports],
    #   text: "Exportar",
    #   path: url_for(controller: "/#{resources}", action: :index, reports: true)
    # }
    ]

    # Generate unique ID for this navigation group
    nav_id = "nav-#{resources}"

    content_tag :div, class: "flex flex-col gap-1.5 items-start justify-start w-full pb-6 px-6" do
      safe_join([
                  content_tag(:div, class: "flex flex-row justify-between items-center w-full cursor-pointer", onclick: "const items = document.getElementById('#{nav_id}'); const chevron = this.querySelector('svg'); items.classList.toggle('hidden'); chevron.classList.toggle('rotate-180');") do
                    safe_join([
                                content_tag(:h3, plural, class: "text-2xs font-mono uppercase font-medium text-muted leading-0"),
                                inline_svg_tag("icons/chevron-down.svg", class: "size-5 bg-white border border-border stroke-body rounded-base p-1 transition-transform duration-200"),
                              ])
                  end,

                  content_tag(:div, id: nav_id, class: "flex flex-col gap-1 items-start justify-start w-full") do
                    safe_join(items.map { |item| crud_nav_button(item) })
                  end,
                ])
    end
  end

  def crud_nav_button(item)
    active = current_page?(item[:path])

    classes = [
      "relative",
      "button",
      "button-small",
      "w-full",
      "!justify-start",
      ("button-outline" if active),
      ("[&>span>span]:text-muted" if active),
      ("[&>svg]:bg-quaternary-100" if active),
      ("[&>svg]:stroke-quaternary-900" if active),
      ("button-link" unless active)
    ].compact.join(" ")

    link_to item[:path], class: classes do
      inline_svg_tag("icons/#{item[:icon]}", class: "size-5 bg-white border border-border rounded-base p-1") +
        content_tag(:span, item[:text].html_safe)
    end
  end

  # == precision_format
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This method formats a number to a specific amount of decimal places.
  #        It ensures that numerical data looks uniform and is easy to align.
  #
  # Attributes:: - *number* @numeric - The raw value to be formatted.
  #             - *precision* @integer - The number of decimal places to show.
  #
  def precision_format(number, precision: 2)

    # Explanation:: This uses the standard Rails utility to round the number and
    #               convert it to a string with the exact number of decimal points.
    formatted_number = number_with_precision(
      number,
      precision: precision,
      separator: ",",
      delimiter: "."
    )

    # Explanation:: This wraps the formatted string in a span tag with a monospaced
    #               font class to ensure numbers align perfectly in tables.
    content_tag(:span, formatted_number, class: "font-mono")
  end
end