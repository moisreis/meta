# frozen_string_literal: true

# Provides UI presentation helpers and reusable rendering abstractions.
#
# This namespace groups presenter objects responsible for encapsulating
# reusable view rendering logic and presentation-specific formatting behavior.
#
# @author Moisés Reis

module Ui

  # Renders monospaced code-style textual values.
  #
  # This presenter formats values using monospace styling and delegates
  # blank-state rendering behavior to {EmptyStatePresenter}.
  class CodePresenter < BasePresenter

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

    # Renders a formatted monospaced textual value.
    #
    # Blank values are delegated to {EmptyStatePresenter}.
    #
    # @param value [String, #to_s, nil] Value rendered inside the code element.
    # @return [ActiveSupport::SafeBuffer] Rendered HTML span element.
    def render(value)
      return @empty.render if value.blank?

      h.content_tag(
        :span,
        value,
        class: "line-clamp-2 font-mono",
        scope: "row"
      )
    end
  end
end
