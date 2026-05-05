# frozen_string_literal: true

# app/presenters/ui/code_presenter.rb
#
# Ui namespace containing presenters responsible for standardized UI rendering.
#
# Renders identification codes with monospaced typography.
#
# @author Moisés Reis
module Ui
  # =============================================================
  #               Ui::CodePresenter
  # =============================================================
  #
  # Provides consistent rendering of identification codes,
  # system IDs, and reference numbers with monospaced styling.
  #
  class CodePresenter < BasePresenter

    # =============================================================
    #                      1. INITIALIZATION
    # =============================================================

    # @param view_context [ActionView::Base] Rails view context providing helper methods.
    def initialize(view_context)
      super
      @empty = EmptyStatePresenter.new(view_context)
    end

    # =============================================================
    #                    2a. RENDER
    # =============================================================

    # Renders an identification code with monospaced font styling.
    #
    # @param value [String, nil] The code string to display
    # @return [ActiveSupport::SafeBuffer] HTML span element or empty-state fallback
    #
    # @example
    #   presenter = Ui::CodePresenter.new(view_context)
    #   presenter.render("ABC-12345")
    #   # => <span class="line-clamp-2 font-mono" scope="row">ABC-12345</span>
    #
    def render(value)
      return @empty.render if value.blank?

      h.content_tag(:span, value, class: "line-clamp-2 font-mono", scope: "row")
    end
  end
end
