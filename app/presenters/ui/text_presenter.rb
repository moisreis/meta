# frozen_string_literal: true

# app/presenters/ui/text_presenter.rb
#
# Ui namespace containing presenters responsible for standardized UI text rendering.
#
# Handles generic text normalization for table UI.
#
# @author Moisés Reis
module Ui
  # =============================================================
  #                 Ui::TextPresenter
  # =============================================================
  #
  # Normalizes and formats textual UI output for table-based layouts.
  #
  class TextPresenter < BasePresenter

    # =============================================================
    #                 1. CONSTANTS & CONFIGURATION
    # =============================================================

    BASE_CLASSES = "line-clamp-2".freeze

    # =============================================================
    #                      2. INITIALIZATION
    # =============================================================

    # @param view_context [ActionView::Base] Rails view context providing helper methods.
    def initialize(view_context)
      super
      @empty = EmptyStatePresenter.new(view_context)
    end

    # =============================================================
    #                      3a. TITLE RENDERING
    # =============================================================

    # Renders a title-style text element for table rows.
    #
    # @param value [String, nil] The text to render as a title.
    # @return [ActiveSupport::SafeBuffer] HTML span element or empty-state fallback.
    def title(value)
      return @empty.render if value.blank?

      h.content_tag(:span, value, class: "#{BASE_CLASSES} font-medium", scope: "row")
    end

    # =============================================================
    #                      3b. TEXT RENDERING
    # =============================================================

    # Renders a truncated text element for table rows.
    #
    # @param value [String, nil] The text to render.
    # @return [ActiveSupport::SafeBuffer] HTML span element with truncated content or empty-state fallback.
    def text(value)
      return @empty.render if value.blank?

      h.content_tag(:span, h.truncate(value, length: 60), class: BASE_CLASSES, scope: "row")
    end
  end
end
