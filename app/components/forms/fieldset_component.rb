# frozen_string_literal: true

# app/components/forms/fieldset_component.rb
#
# Component responsible for grouping related form fields under a common
# semantic fieldset, optionally displaying a title and description.
#
# This component is used to improve form structure, accessibility, and
# visual grouping consistency across the application.
#
# @author  Moisés Reis

class Forms::FieldsetComponent < ApplicationComponent

  # == Class Methods ==========================================================

  # Initializes the fieldset component with semantic legend and metadata hooks.
  #
  # @param title [String] The legend or main heading for the fieldset.
  # @param description [String, nil] Optional helper text to explain the group's purpose.
  # @return [Forms::FieldsetComponent]
  def initialize(title:, description: nil)
    @title = title
    @description = description
  end

end