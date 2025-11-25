# === nav_helper
#
# @author Moisés Reis
# @added 11/25/2025
# @package *Meta*
# @description This file contains methods that generate standardized navigation components for the application,
#              primarily focusing on creating sidebar menu structures for CRUD (Create, Read, Update, Delete) resources.
#              The explanations are in the present simple tense.
# @category *Helper*
#
# Usage:: - *[What]* This code block creates dynamic, reusable navigation menus, especially for application sections
#           that manage core resources like **InvestmentFund** or **User**.
#         - *[How]* It accepts a model class, determines its path and names, calculates the record count,
#           and then builds a structured list of links (Index, New, Reports) wrapped in a custom HTML layout.
#         - *[Why]* It ensures that the sidebar navigation across different resources is visually consistent,
#           correctly links to the necessary CRUD actions, and automatically updates the count of records.
#
# Attributes:: - *model_class* @Class - The Ruby class representing the resource (e.g., `InvestmentFund`).
#              - *singular* @string - The singular name of the resource for display (e.g., "Fundo").
#              - *plural* @string - The plural name of the resource for display (e.g., "Fundos").
#
module NavHelper

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

    # Explanation:: This retrieves the human-readable singular name of the model (e.g., "Fund")
    #               to use in the navigation, falling back to the parameter if provided.
    singular ||= model_class.model_name.human

    # Explanation:: This retrieves the human-readable plural name of the model (e.g., "Funds")
    #               and forces the plural form using `count: 2`, falling back to the parameter if provided.
    plural ||= model_class.model_name.human(count: 2)

    # Explanation:: This determines the web route key for the model (e.g., `investment_funds`)
    #               which is used to construct the correct URL path for the controller.
    resources = model_class.model_name.route_key

    # Explanation:: This queries the database to quickly count the total number of
    #               records for the model, which is displayed next to the plural name.
    count = model_class.count

    # Explanation:: This defines the default set of SVG icons to be used for the
    #               three standard navigation links (Index, New, Reports).
    default_icons = {
      index: "wallet.svg",
      new: "add.svg",
      reports: "article.svg"
    }

    # Explanation:: This combines the `default_icons` with any custom icons provided
    #               by the user, ensuring the keys are symbolized for proper merging.
    icon_set = default_icons.merge(icons.symbolize_keys)

    # Explanation:: This constructs an array containing the data for each navigation item,
    #               including the icon, display text (with the record count), and the full URL path.
    items = [
      {
        icon: icon_set[:index],
        text: "#{plural} <b>(#{count})</b>",
        path: url_for(controller: "/#{resources}", action: :index)
      },
      {
        icon: icon_set[:new],
        text: "Adicionar",
        path: url_for(controller: "/#{resources}", action: :new)
      },
      {
        icon: icon_set[:reports],
        text: "Relatórios",
        path: url_for(controller: "/#{resources}", action: :index, reports: true)
      }
    ]

    # Explanation:: This creates the main HTML container for the entire navigation group,
    #               applying styles for vertical layout and full width.
    content_tag :div, class: "flex flex-col gap-1.5 items-start justify-start w-full" do
      safe_join([
                  content_tag(:div, class: "flex flex-row justify-between items-center w-full") do
                    safe_join([
                                content_tag(:h3, plural, class: "text-2xs font-semibold uppercase text-quaternary-600 leading-0"),
                                inline_svg_tag("icons/keyboard_arrow_down.svg", class: "size-4"),
                              ])
                  end,

                  # Explanation:: This iterates over the `items` array and calls `crud_nav_button`
                  #               to generate the HTML link for each item in the list.
                  safe_join(items.map { |item| crud_nav_button(item) })
                ])
    end
  end

  # == crud_nav_button
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This method generates a single, stylized navigation button for use within the CRUD sidebar.
  #        It automatically applies active styling if the link matches the current page.
  #
  # Attributes:: - *item* @Hash - A hash containing the button's properties: `:icon`, `:text`, and `:path`.
  #
  def crud_nav_button(item)

    # Explanation:: This checks if the current browser URL matches the link's URL (`item[:path]`),
    #               which determines if the button should be visually highlighted as active.
    active = current_page?(item[:path])

    # Explanation:: This builds a list of CSS classes, conditionally adding the `button-secondary`
    #               class if the link is active, and the `button-link` class if it is not.
    classes = [
      "button",
      "button-small",
      "w-full",
      "!justify-start",
      ("button-secondary" if active),
      ("button-link" unless active)
    ].compact.join(" ")

    # Explanation:: This generates the final HTML link, embedding the SVG icon and the
    #               HTML-safe text, and applying the calculated `classes` for styling.
    link_to item[:path], class: classes do
      inline_svg_tag("icons/#{item[:icon]}", class: "size-4") +
        content_tag(:span, item[:text].html_safe, class: "relative")
    end
  end
end