# frozen_string_literal: true

# Provides UI presentation helpers and reusable rendering abstractions.
#
# This namespace groups presenter objects responsible for encapsulating
# reusable view rendering logic and presentation-specific formatting behavior.
#
# @author Moisés Reis

module Ui

  # Renders formatted date and time-related presentation values.
  #
  # This presenter provides standardized formatting helpers for:
  # - calendar dates
  # - relative timestamps
  # - latest collection dates
  #
  # Blank-state rendering behavior is delegated to {EmptyStatePresenter}.
  class DatePresenter < BasePresenter

    # ==========================================================================
    # CONSTANTS
    # ==========================================================================

    # Shared CSS utility classes applied to formatted date values.
    #
    # @return [String] CSS class list used for formatted date rendering.
    BASE_CLASSES = "line-clamp-2 font-mono".freeze

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

    # Renders a formatted calendar date.
    #
    # Dates are formatted using the Brazilian DD/MM/YYYY standard.
    #
    # @param value [Date, Time, DateTime, nil] Value converted into a date.
    # @return [ActiveSupport::SafeBuffer] Rendered HTML span element.
    def date(value)
      return @empty.render if value.blank?

      formatted = value.to_date.strftime("%d/%m/%Y")

      h.content_tag(
        :span,
        formatted,
        class: BASE_CLASSES,
        scope: "row"
      )
    end

    # Renders the most recent date from a collection.
    #
    # The collection is ordered descending by the specified attribute and
    # the latest available value is rendered through {#date}.
    #
    # @param collection [ActiveRecord::Relation] Collection queried for dates.
    # @param attribute [Symbol] Attribute used for ordering and rendering.
    # @return [ActiveSupport::SafeBuffer] Rendered HTML date element.
    def latest_date(collection, attribute: :date)
      record = collection.order(attribute => :desc).first

      return @empty.render if record.blank? || record.send(attribute).blank?

      date(record.send(attribute))
    end

    # Renders a relative time expression.
    #
    # Example outputs:
    # - "5 minutes"
    # - "2 days"
    # - "about 1 month"
    #
    # @param value [Time, DateTime, nil] Timestamp used for relative formatting.
    # @return [ActiveSupport::SafeBuffer] Rendered HTML span element.
    def relative(value)
      return @empty.render if value.blank?

      content = h.time_ago_in_words(value)

      h.content_tag(
        :span,
        content,
        class: "text-xs text-muted italic"
      )
    end
  end
end
