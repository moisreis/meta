# frozen_string_literal: true

class Forms::TextareaComponent < ApplicationComponent
  include FormStyles

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

  # ==========================================================================
  # ERROR HANDLING
  # ==========================================================================

  def has_error?
    @form.object.respond_to?(:errors) && @form.object.errors[@name].present?
  end

  def error_message
    return unless has_error?
    @form.object.errors[@name].first
  end

  # ==========================================================================
  # STYLE HELPERS
  # ==========================================================================

  def textarea_classes
    [
      INPUT_BASE_CLASSES,
      INPUT_HOVER_CLASSES,
      INPUT_FOCUS_CLASSES,
      TEXTAREA_EXTRA_CLASSES
    ].join(" ")
  end

  private

  attr_reader :form, :name, :label, :desc, :placeholder, :rows,
              :is_half_width, :is_inactive, :is_small
end