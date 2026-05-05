# frozen_string_literal: true

# app/presenters/ui/fk_presenter.rb
#
# Ui namespace containing presenters responsible for standardized UI rendering.
#
# Renders foreign key references as outlined badges.
#
# @author Moisés Reis
module Ui
  # =============================================================
  #               Ui::FkPresenter
  # =============================================================
  #
  # Provides consistent rendering of foreign key references,
  # relation IDs, and cross-table references with badge styling.
  #
  class FkPresenter < BasePresenter

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

    # Renders a foreign key reference as a small outlined badge.
    #
    # @param value [Object, nil] The reference value (ID, code, or identifier)
    # @return [ActiveSupport::SafeBuffer] HTML badge span or empty-state fallback
    #
    # @example
    #   presenter = Ui::FkPresenter.new(view_context)
    #   presenter.render(42)
    #   # => <span class="line-clamp-2 badge badge-outline !text-2xs" scope="row">42</span>
    #
    def render(value)
      return @empty.render if value.blank?

      h.content_tag(:span, value, class: "line-clamp-2 badge badge-outline !text-2xs", scope: "row")
    end
  end
end
