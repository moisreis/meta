module NavHelper

  def crud_nav_for(model_class, singular: nil, plural: nil, icons: {})

    singular ||= model_class.model_name.human

    plural ||= model_class.model_name.human(count: 2)

    resources = model_class.model_name.route_key

    default_icons = {
      index: "wallet.svg",
      new: "plus.svg",
      reports: "file-text.svg"
    }

    icon_set = default_icons.merge(icons.symbolize_keys)

    items = [
      {
        icon: icon_set[:index],
        text: "#{plural}".html_safe,
        path: url_for(controller: "/#{resources}", action: :index)
      }
    ]

    nav_id = "nav-#{resources}"

    content_tag :div, class: "flex flex-col gap-1.5 items-center justify-center w-full" do
      safe_join([
                  content_tag(:div, id: nav_id, class: "flex flex-col gap-1 items-start justify-start w-full") do
                    safe_join(items.map { |item| crud_nav_button(item) })
                  end
                ])
    end
  end

  def crud_nav_button(item)
    active = current_page?(item[:path])

    content_id = "desc-#{item[:text].parameterize}"

    classes = [
      "relative",
      "button",
      "button-icon",
      "section-desc-button",
      ("button-ghost" if !active),
      ("button-honeysuckle" if active)
    ].compact.join(" ")

    button_link = link_to item[:path],
                          class: classes,
                          data: { tippy_target: "##{content_id}" } do
      inline_svg_tag("icons/#{item[:icon]}", class: "")
    end

    popover_content = content_tag(:div, id: content_id, class: "hidden") do
      item[:text]
    end

    safe_join([button_link, popover_content])
  end
end