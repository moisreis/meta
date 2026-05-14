# frozen_string_literal: true

# Component responsible for rendering a table row with optional action menu
# support (show, edit, destroy) and dynamic cell rendering.
#
# This component standardizes row rendering across tabular UI structures and
# provides consistent action menu identification.
#
# @author Moisés Reis
class Modules::TableRowComponent < ApplicationComponent

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # @param cells [Array<String>] The raw or HTML content for each column.
  # @param model_id [Integer, String] The unique identifier for the record.
  # @param show_path [String, nil] URL for the show action.
  # @param edit_path [String, nil] URL for the edit action.
  # @param destroy_path [String, nil] URL for the destroy action.
  def initialize(cells:, model_id:, show_path: nil, edit_path: nil, destroy_path: nil)
    @cells        = cells
    @model_id     = model_id
    @show_path    = show_path
    @edit_path    = edit_path
    @destroy_path = destroy_path
  end

  # ==========================================================================
  # QUERY METHODS
  # ==========================================================================

  # Checks if any action paths are present to determine if the menu should render.
  # @return [Boolean]
  def actions?
    @show_path.present? || @edit_path.present? || @destroy_path.present?
  end

  # Generates a unique ID for the dropdown menu.
  # @return [String]
  def action_menu_id
    "options-menu-#{@model_id}"
  end

  # Formats the cells for development logging by stripping HTML tags.
  # @return [String]
  def log_output
    @cells.map { |cell| ActionController::Base.helpers.strip_tags(cell.to_s) }.join(', ')
  end
end
