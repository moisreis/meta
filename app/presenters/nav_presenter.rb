# app/presenters/nav_presenter.rb
#
# Renders navigation UI blocks from precomputed navigation items.
#
# This presenter is responsible ONLY for HTML rendering.
# All business logic and routing decisions are delegated to NavItemsBuilder.
#
# @author Moisés Reis
class NavPresenter

  # =============================================================
  #                      1. INITIALIZATION
  # =============================================================

  # @param view_context [ActionView::Base] Rails view context providing helper methods.
  def initialize(view_context)
    @view = view_context
  end

  # =============================================================
  #                        2a. RENDER
  # =============================================================

  # Renders a navigation section block.
  #
  # @param label [String] Section label displayed in the header.
  # @param nav_id [String] DOM id for the items container.
  # @param items [Array<Hash>] Navigation items with :path, :text, and :icon.
  # @return [ActiveSupport::SafeBuffer] Rendered navigation block.
  def render(label:, nav_id:, items:)
    @view.content_tag(:div, class: "flex flex-col justify-start items-start gap-1.5 w-full") do
      @view.safe_join([
        section_header(label),
        items_container(nav_id, items)
      ])
    end
  end

  private

  # =============================================================
  #                    3a. SECTION HEADER
  # =============================================================

  # Renders the navigation section header label.
  #
  # @param label [String] Section label text.
  # @return [ActiveSupport::SafeBuffer] Header HTML block.
  def section_header(label)
    @view.content_tag(:div, class: "flex flex-row justify-start items-center w-full") do
      @view.content_tag(
        :span,
        label,
        class: "px-3 text-3xs font-mono tracking-widest font-semibold uppercase text-neutral-50 opacity-40"
      )
    end
  end

  # =============================================================
  #                    3b. ITEMS CONTAINER
  # =============================================================

  # Renders the container holding navigation buttons.
  #
  # @param nav_id [String] DOM id for container.
  # @param items [Array<Hash>] Navigation item definitions.
  # @return [ActiveSupport::SafeBuffer] Container HTML block.
  def items_container(nav_id, items)
    @view.content_tag(:div, id: nav_id, class: "flex flex-col gap-1 px-1.5 w-full") do
      @view.safe_join(items.map { |item| nav_button(item) })
    end
  end

  # =============================================================
  #                    3c. NAVIGATION BUTTON
  # =============================================================

  # Renders a single navigation link/button.
  #
  # @param item [Hash] Navigation item (:path, :text, :icon).
  # @return [ActiveSupport::SafeBuffer] Navigation link HTML.
  def nav_button(item)
    active = @view.current_page?(item[:path])

    classes = [
      "relative button button-small w-full flex flex-row justify-start",
      active ? "button-sidebar--active" : "button-sidebar"
    ].join(" ")

    @view.link_to(item[:path], class: classes) do
      @view.safe_join([
        @view.inline_svg_tag("icons/#{item[:icon]}", class: "w-4 h-4"),
        @view.content_tag(:span, item[:text], class: "text-sm font-medium")
      ])
    end
  end
end
