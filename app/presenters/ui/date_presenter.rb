# frozen_string_literal: true

# app/presenters/ui/date_presenter.rb
#
# Ui namespace containing presenters responsible for standardized UI rendering.
#
# Handles date formatting and temporal display.
#
# @author Moisés Reis
module Ui
  # =============================================================
  #                 Ui::DatePresenter
  # =============================================================
  #
  # Provides consistent formatting and aggregation logic for date-based
  # UI presentation concerns.
  #
  class DatePresenter < BasePresenter

    # =============================================================
    #                 1. CONSTANTS & CONFIGURATION
    # =============================================================

    BASE_CLASSES = "line-clamp-2 font-mono".freeze

    # =============================================================
    #                      2. INITIALIZATION
    # =============================================================

    # @param view_context [ActionView::Base] Rails view context providing helper methods.
    def initialize(view_context)
      super
      @empty = EmptyStatePresenter.new(view_context)
    end

    # =============================================================
    #                      3a. DATE RENDERING
    # =============================================================

    # Renders a formatted date value.
    #
    # @param value [Date, Time, DateTime, nil] The date-like value to render.
    # @return [ActiveSupport::SafeBuffer] HTML span element or empty-state fallback.
    def date(value)
      return @empty.render if value.blank?

      formatted = value.to_date.strftime("%d/%m/%Y")
      h.content_tag(:span, formatted, class: BASE_CLASSES, scope: "row")
    end

    # =============================================================
    #                  3b. LATEST DATE RENDERING
    # =============================================================

    # Renders the most recent date from a collection.
    #
    # @param collection [ActiveRecord::Relation, Enumerable] Collection of records.
    # @param attribute [Symbol] Attribute name containing the date value.
    # @return [ActiveSupport::SafeBuffer] HTML span element or empty-state fallback.
    def latest_date(collection, attribute: :date)
      record = collection.order(attribute => :desc).first
      return @empty.render if record.blank? || record.send(attribute).blank?

      date(record.send(attribute))
    end

    # =============================================================
    #                 3c. RELATIVE TIME RENDERING
    # =============================================================

    # Renders a relative time string (e.g., "há 2 meses").
    #
    # @param value [Date, Time, DateTime, nil] The date-like value to evaluate.
    # @return [ActiveSupport::SafeBuffer] HTML span element or empty-state fallback.
    def relative(value)
      return @empty.render if value.blank?

      content = h.time_ago_in_words(value)
      h.content_tag(:span, content, class: "text-xs text-muted italic")
    end
  end
end
