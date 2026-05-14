# frozen_string_literal: true

# Provides UI presentation helpers and reusable rendering abstractions.
#
# This namespace groups presenter objects responsible for encapsulating
# reusable view rendering logic and presentation-specific formatting behavior.
#
# @author Moisés Reis

module Ui

  # Renders styled foreign-key and identifier reference values.
  #
  # This presenter formats reference values using compact outlined badge
  # styling and delegates blank-state rendering behavior to
  # {EmptyStatePresenter}.
  class FkPresenter < BasePresenter

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

    # Renders a styled foreign-key or identifier reference value.
    #
    # Blank values are delegated to {EmptyStatePresenter}.
    #
    # @param value [String, Numeric, #to_s, nil] Reference value rendered in badge format.
    # @return [ActiveSupport::SafeBuffer] Rendered HTML span element.
    def render(value)
      return @empty.render if value.blank?

      h.content_tag(
        :span,
        value,
        class: "line-clamp-2 badge badge-outline !text-2xs",
        scope: "row"
      )
    end
  end
end
