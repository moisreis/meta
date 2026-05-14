# frozen_string_literal: true

# Provides UI presentation helpers and reusable rendering abstractions.
#
# This namespace groups presenter objects responsible for encapsulating
# reusable view rendering logic and presentation-specific formatting behavior.
#
# @author Moisés Reis

module Ui

  # Renders boolean and state-based presentation values.
  #
  # This presenter provides helper methods for:
  # - localized boolean labels
  # - visual state classification
  #
  # Unlike markup-oriented presenters, this object primarily returns
  # primitive presentation values and symbolic state identifiers.
  class StatePresenter < BasePresenter

    # ==========================================================================
    # PUBLIC METHODS
    # ==========================================================================

    # Resolves a human-readable boolean label.
    #
    # Default labels:
    # - true  => "Sim"
    # - false => "Não"
    #
    # Supported label aliases:
    # - :true
    # - :false
    # - :positive
    # - :negative
    #
    # @param value [Boolean, nil] Boolean value evaluated for labeling.
    # @param labels [Hash] Optional custom label mapping.
    # @option labels [String] :true Custom label used for true values.
    # @option labels [String] :false Custom label used for false values.
    # @option labels [String] :positive Alias label used for true values.
    # @option labels [String] :negative Alias label used for false values.
    # @param zero_label [String] Fallback label used for nil or unknown values.
    # @return [String] Resolved boolean label.
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

    # Resolves a symbolic visual status based on a boolean value.
    #
    # @param value [Boolean, nil] Boolean value evaluated for status resolution.
    # @param positive [Symbol] Status returned for true values.
    # @param negative [Symbol] Status returned for false values.
    # @param default [Symbol] Status returned for nil values.
    # @return [Symbol] Resolved visual state identifier.
    def boolean_status(value, positive:, negative:, default: :default)
      return default if value.nil?

      value ? positive : negative
    end
  end
end
