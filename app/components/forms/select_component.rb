# frozen_string_literal: true

# app/components/forms/select_component.rb
#
# Component responsible for rendering a form-backed select dropdown with
# TomSelect enhancement, validation-aware styling, and accessibility attributes.
#
# @author  Moisés Reis

class Forms::SelectComponent < ApplicationComponent

  # == Concerns ===============================================================

  include FormStyles


  # == Class Methods ==========================================================

  # Initializes the select dropdown component with configuration and collection assets.
  #
  # @param f [ActionView::Helpers::FormBuilder] The ActiveService or ActiveRecord form builder instance.
  # @param name [Symbol, String] The attribute name mapped to the database record or form param.
  # @param options_collection [Array, Enumerable] List of options formatting the key-value options pair.
  # @param label [String, nil] The title text displayed in the label element.
  # @param desc [String, nil] Supporting description or help text.
  # @param rich [Boolean] Triggers enhanced searching and client-side UI hydration via TomSelect.
  # @param selected [Object, nil] Pre-selected value mapping key if pre-filled state is needed.
  # @param is_inactive [Boolean] Toggles disabled flag state on form boundaries.
  # @param is_half_width [Boolean] Restricts component container layout space on desktop layouts.
  # @param is_small [Boolean] Applies dense structural down-sizing attributes.
  # @return [Forms::SelectComponent]
  def initialize(
    f:,
    name:,
    options_collection:,
    label: nil,
    desc: nil,
    rich: false,
    selected: nil,
    is_inactive: false,
    is_half_width: false,
    is_small: false
  )
    @f                  = f
    @name               = name
    @options_collection = options_collection
    @label              = label
    @desc               = desc
    @rich               = rich
    @selected           = selected
    @is_inactive        = is_inactive
    @is_half_width      = is_half_width
    @is_small           = is_small
  end


  # == Instance Methods =======================================================

  # -- Error Handling ---------------------------------------------------------

  # Evaluates whether the underlying record context contains active validation errors.
  #
  # @return [Boolean] True if database backing object has errors assigned to this field name.
  def has_error?
    @f.object.respond_to?(:errors) && @f.object.errors[@name].present?
  end

  # Extracts the first context-aware validation message if an error state exists.
  #
  # @return [String, nil] The full localized validation error message, or nil if valid.
  def error_message
    return unless has_error?
    @f.object.errors.full_messages_for(@name).first
  end

end