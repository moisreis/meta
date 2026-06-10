# frozen_string_literal: true

# app/components/forms/textarea_component.rb
#
# Component responsible for rendering a form-backed multi-line textarea input
# field with validation-aware styling, custom row sizes, and accessibility attributes.
#
# @author  Moisés Reis

class Forms::TextareaComponent < ApplicationComponent

  # == Concerns ===============================================================

  include FormStyles


  # == Class Methods ==========================================================

  # Initializes the textarea field component with dimension parameters and validation constraints.
  #
  # @param form [ActionView::Helpers::FormBuilder] The ActiveService or ActiveRecord form builder instance.
  # @param name [Symbol, String] The attribute name mapped to the database record or form param.
  # @param label [String, nil] The title text displayed in the label element.
  # @param desc [String, nil] Supporting description or help text.
  # @param placeholder [String, nil] Placeholder hint string for empty states.
  # @param rows [Integer] Core vertical line structural constraint capacity (default: 4).
  # @param is_half_width [Boolean] Restricts component container layout space on desktop layouts.
  # @param is_inactive [Boolean, nil] Toggles disabled flag state on form boundaries.
  # @param is_small [Boolean] Applies dense structural down-sizing attributes.
  # @return [Forms::TextareaComponent]
  def initialize(
    form:,
    name:,
    label: nil,
    desc: nil,
    placeholder: nil,
    rows: 4,
    is_half_width: false,
    is_inactive: nil,
    is_small: false
  )
    @form          = form
    @name          = name
    @label         = label
    @desc          = desc
    @placeholder   = placeholder
    @rows          = rows
    @is_half_width = is_half_width
    @is_inactive   = is_inactive
    @is_small      = is_small
  end


  # == Instance Methods =======================================================

  # -- Error Handling ---------------------------------------------------------

  # Evaluates whether the underlying record context contains active validation errors.
  #
  # @return [Boolean] True if database backing object has errors assigned to this field name.
  def has_error?
    @form.object.respond_to?(:errors) && @form.object.errors[@name].present?
  end

  # Extracts the first context-aware validation message if an error state exists.
  #
  # @return [String, nil] The structural validation error message, or nil if valid.
  def error_message
    return unless has_error?
    @form.object.errors[@name].first
  end

  # -- Style Helpers ----------------------------------------------------------

  # Compiles the final collection of styling utilities applied to the markup textarea node.
  #
  # @return [String] Concatenated string containing core structural, interactive, and multi-line overrides.
  def textarea_classes
    [
      INPUT_BASE_CLASSES,
      INPUT_HOVER_CLASSES,
      INPUT_FOCUS_CLASSES,
      TEXTAREA_EXTRA_CLASSES
    ].join(" ")
  end


  private


  # == Private Methods ========================================================

  # -- Attributes -------------------------------------------------------------

  attr_reader :form, :name, :label, :desc, :placeholder, :rows,
              :is_half_width, :is_inactive, :is_small

end