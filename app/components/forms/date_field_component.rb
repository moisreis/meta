# frozen_string_literal: true

# app/components/forms/date_field_component.rb
#
# Renders a form-backed date/text field with optional icon,
# contextual description, accessibility attributes, and
# validation-aware styling.
#
# @author  Moisés Reis

class Forms::DateFieldComponent < ApplicationComponent

  # == Concerns ===============================================================

  include FormStyles


  # == Class Methods ==========================================================

  # Initializes the date field component with design constraints and structural data hooks.
  #
  # @param f [ActionView::Helpers::FormBuilder] The ActiveService or ActiveRecord form builder instance.
  # @param name [Symbol, String] The attribute name mapped to the database record or form param.
  # @param label [String, nil] The title text displayed in the label element.
  # @param desc [String, nil] Supporting description or help text.
  # @param placeholder [String] Placeholder hint string for empty states.
  # @param field_type [Symbol] ActionView form wrapper method type (e.g., :date_field, :text_field).
  # @param value [Object, nil] Overriding data value if pre-filled state is needed.
  # @param data [Hash] Custom data attribute parameters for JavaScript/Stimulus hookup.
  # @param icon_name [String, nil] Lucide icon name for optional inner structural element.
  # @param is_inactive [Boolean] Toggles disabled flag state on form boundaries.
  # @param is_half_width [Boolean] Restricts component container layout space on desktop layouts.
  # @param is_small [Boolean] Applies dense structural down-sizing attributes.
  # @return [Forms::DateFieldComponent]
  def initialize(
    f:,
    name:,
    label: nil,
    desc: nil,
    placeholder: "Escolha uma data",
    field_type: :date_field,
    value: nil,
    data: {},
    icon_name: nil,
    is_inactive: false,
    is_half_width: false,
    is_small: false
  )
    @f             = f
    @name          = name
    @label         = label
    @desc          = desc
    @placeholder   = placeholder
    @field_type    = field_type
    @value         = value
    @data          = data
    @icon_name     = icon_name
    @is_inactive   = is_inactive
    @is_half_width = is_half_width
    @is_small      = is_small
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

  # -- Style Helpers ----------------------------------------------------------

  # Compiles the final collection of styling utilities applied to the markup input node.
  #
  # @return [String] Concatenated string containing core structural, interactive, and sizing utility classes.
  def input_classes
    [
      INPUT_BASE_CLASSES,
      INPUT_HOVER_CLASSES,
      INPUT_FOCUS_CLASSES,
      (INPUT_SMALL_CLASSES if @is_small)
    ].compact.join(" ")
  end

end