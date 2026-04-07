# frozen_string_literal: true

# == NavHelper
#
# @author Moisés Reis
# @project Meta Investimentos
# @added 06/04/2026
# @package Meta
# @category Helpers
#
# @description
#   Provides utility methods for generating navigation elements, specifically
#   standardized CRUD navigation blocks and buttons for the application sidebar.
#
# @example Basic usage in a view
#   crud_nav_for(User)
#
module NavHelper
  # == crud_nav_for
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Generates a structured navigation section for a specific model class,
  #   including links for listing and creating records.
  #
  # @param model_class [Class] The ActiveRecord model class to base the navigation on
  # @param singular [String] Custom singular label (default: model human name)
  # @param plural [String] Custom plural label (default: model human name count 2)
  # @param icons [Hash] Custom icons for :index and :new actions
  # @param index_path [String] Custom URL for the index action
  # @param new_path [String] Custom URL for the new action
  # @param show_new [Boolean] Whether to include the 'Add New' button (default: true)
  # @return [String] HTML safe navigation block
  #
  # @example
  #   crud_nav_for(EconomicIndex, icons: { index: "chart.svg" })
  #
  def crud_nav_for(model_class, singular: nil, plural: nil, icons: {}, index_path: nil, new_path: nil, show_new: true)
    singular ||= model_class.model_name.human
    plural   ||= model_class.model_name.human(count: 2)

    resources = model_class.model_name.route_key

    default_icons = { index: "wallet.svg", new: "plus.svg" }
    icon_set = default_icons.merge(icons.symbolize_keys)

    items = [
      {
        icon: icon_set[:index],
        text: "Ver todos",
        path: index_path || url_for(controller: "/#{resources}", action: :index)
      }
    ]

    if show_new
      items << {
        icon: icon_set[:new],
        text: "Adicionar novo",
        path: new_path || url_for(controller: "/#{resources}", action: :new)
      }
    end

    nav_id = "nav-#{resources}"

    content_tag :div, class: "flex flex-col gap-1.5 w-full" do
      safe_join([
                  content_tag(:div, class: "flex flex-row justify-center items-center w-full") do
                    safe_join([
                                content_tag(:span, plural, class: "px-3 text-3xs font-mono tracking-widest font-semibold uppercase text-neutral-50 opacity-30"),
                                content_tag(:div, nil, class: "h-[2px] bg-neutral-800 w-full opacity-30")
                              ])
                  end,
                  content_tag(:div, id: nav_id, class: "flex flex-col gap-1 px-1.5 w-full") do
                    safe_join(items.map { |item| crud_nav_button(item) })
                  end
                ])
    end
  end

  # == crud_nav_button
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Renders a single navigation button with an icon and text, applying active
  #   styles if the current page matches the item path.
  #
  # @param item [Hash] A hash containing :icon, :text, and :path
  # @return [String] HTML safe link button
  #
  # @see #crud_nav_for
  #
  def crud_nav_button(item)
    active = current_page?(item[:path])

    classes = [
      "relative", "button", "button-small", "w-full", "flex flex-row justify-start",
      ("button-sidebar" unless active),
      ("button-primary" if active)
    ].compact.join(" ")

    link_to item[:path], class: classes do
      safe_join([
                  inline_svg_tag("icons/#{item[:icon]}", class: "w-4 h-4"),
                  content_tag(:span, item[:text], class: "text-sm font-medium")
                ])
    end
  end
end
