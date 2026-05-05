# frozen_string_literal: true

# app/components/application_component.rb
#
# Base component class shared across the entire ViewComponent layer.
#
# All application components inherit from this class instead of
# {ViewComponent::Base}, allowing shared helpers, presenter
# integration, and reusable rendering utilities to be centralized
# in a single location.
#
# Responsibilities:
# - Shared presenter instantiation
# - Shared helper delegation
# - Common SVG icon rendering helpers
#
# @example
#   class Users::CardComponent < ApplicationComponent
#   end
#
class ApplicationComponent < ViewComponent::Base
  delegate :formatted_timestamp, to: :helpers

  private

  # ===========================================================
  #                 1. PRESENTER INTEGRATION
  # ===========================================================

  # Instantiates a presenter with access to the current
  # Rails view context and helper methods.
  #
  # This allows presenters to use helpers such as:
  # - number_to_currency
  # - link_to
  # - image_tag
  # - content_tag
  #
  # @param presenter_class [Class]
  # @param subject [Object]
  # @return [Object]
  def build_presenter(presenter_class, subject)
    presenter_class.new(subject, helpers)
  end

  # ===========================================================
  #                    2. ICON RENDERING
  # ===========================================================

  # Renders an inline SVG icon from the application's icon set.
  #
  # Icons are resolved relative to:
  #   app/assets/images/icons/
  #
  # @param name [String, Symbol]
  # @param options [Hash]
  # @return [String, nil]
  #
  # @example
  #   render_icon("user")
  #
  #   render_icon("wallet", class: "size-4")
  #
  def render_icon(name, **options)
    return unless name.present?

    helpers.inline_svg_tag("icons/#{name}.svg", **options)
  end
end