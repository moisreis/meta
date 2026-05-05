# frozen_string_literal: true

# app/presenters/ui/state_presenter.rb
#
# Provides helper methods responsible for transforming boolean
# values into normalized UI presentation states.
#
# This presenter centralizes label and status formatting logic
# used by visual components, badges, and state indicators.
#
# @example Boolean labels
#   presenter.boolean_label(true)
#   # => "Sim"
#
#   presenter.boolean_label(false)
#   # => "Não"
#
# @example Boolean status mapping
#   presenter.boolean_status(
#     true,
#     positive: :success,
#     negative: :danger
#   )
#   # => :success
#
# @author Moisés Reis
module Ui
  class StatePresenter < BasePresenter
    # ===========================================================
    #                    1. BOOLEAN LABELS
    # ===========================================================

    # Converts a boolean value into a human-readable label.
    #
    # Supports custom label mappings and fallback values.
    #
    # @param value [Boolean, nil]
    # @param labels [Hash]
    # @param zero_label [String]
    # @return [String]
    def boolean_label(value, labels: {}, zero_label: "-")
      return zero_label if value.nil?

      case value
      when true
        labels.fetch(:true, labels.fetch(:positive, "Sim"))
      when false
        labels.fetch(:false, labels.fetch(:negative, "Não"))
      else
        zero_label
      end
    end

    # ===========================================================
    #                    2. BOOLEAN STATUS
    # ===========================================================

    # Converts a boolean value into a symbolic UI status.
    #
    # Useful for determining component variants such as
    # success, danger, warning, or neutral states.
    #
    # @param value [Boolean, nil]
    # @param positive [Symbol]
    # @param negative [Symbol]
    # @param default [Symbol]
    # @return [Symbol]
    def boolean_status(value, positive:, negative:, default: :default)
      return default if value.nil?

      value ? positive : negative
    end
  end
end