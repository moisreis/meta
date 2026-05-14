# frozen_string_literal: true

# Component responsible for grouping related form fields under a common
# semantic fieldset, optionally displaying a title and description.
#
# This component is used to improve form structure, accessibility, and
# visual grouping consistency across the application.
#
# @author Moisés Reis

class Forms::FieldsetComponent < ApplicationComponent

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # @param title [String] The legend or main heading for the fieldset.
  # @param description [String, nil] Optional helper text to explain the group's purpose.
  def initialize(title:, description: nil)
    @title = title
    @description = description
  end
end
