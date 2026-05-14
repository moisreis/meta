# frozen_string_literal: true

# Provides UI presentation helpers and reusable rendering abstractions.
#
# This namespace groups presenter objects responsible for encapsulating
# reusable view rendering logic and presentation-specific formatting behavior.
#
# @author Moisés Reis

module Ui

  # Renders formatted textual presentation values.
  #
  # This presenter provides standardized rendering helpers for:
  # - titles
  # - generic text content
  #
  # Blank-state rendering behavior is delegated to {EmptyStatePresenter}.
  class TextPresenter < BasePresenter

    # ==========================================================================
    # CONSTANTS
    # ==========================================================================

    # Shared CSS utility classes applied to textual content rendering.
    #
    # @return [String] CSS class list used for text rendering.
    BASE_CLASSES = "line-clamp-2".freeze

    # ==========================================================================
    # INITIALIZATION
    # ==========================================================================

    # Initializes the presenter.
    #
    # @param view_context [ActionView::Base] Rails view context instance.
    def initialize(view_context)
      super

      @empty = EmptyStatePresenter.new(view_context)
    end

    # ==========================================================================
    # PUBLIC METHODS
    # ==========================================================================

    # Renders emphasized title-style textual content.
    #
    # Blank values are delegated to {EmptyStatePresenter}.
    #
    # @param value [String, #to_s, nil] Title content rendered in emphasized style.
    # @return [ActiveSupport::SafeBuffer] Rendered HTML span element.
    def title(value)
      return @empty.render if value.blank?

      h.content_tag(
        :span,
        value,
        class: "#{BASE_CLASSES} font-medium",
        scope: "row"
      )
    end

    # Renders truncated textual content.
    #
    # Content exceeding 60 characters is truncated automatically.
    #
    # Blank values are delegated to {EmptyStatePresenter}.
    #
    # @param value [String, #to_s, nil] Text content rendered in standard style.
    # @return [ActiveSupport::SafeBuffer] Rendered HTML span element.
    def text(value)
      return @empty.render if value.blank?

      h.content_tag(
        :span,
        h.truncate(value, length: 60),
        class: BASE_CLASSES,
        scope: "row"
      )
    end
  end
end
