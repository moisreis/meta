# frozen_string_literal: true

# Component responsible for rendering a form-backed select dropdown with
# TomSelect enhancement, validation-aware styling, and accessibility attributes.
#
# @author Moisés Reis

class Forms::SelectComponent < ApplicationComponent
  include FormStyles

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

  # ==========================================================================
  # ERROR HANDLING
  # ==========================================================================

  def has_error?
    @f.object.respond_to?(:errors) && @f.object.errors[@name].present?
  end

  def error_message
    return unless has_error?
    @f.object.errors.full_messages_for(@name).first
  end
end