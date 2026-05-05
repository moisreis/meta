# frozen_string_literal: true

class Modules::TableRowComponent < ApplicationComponent

  def initialize(cells:, model_id:, show_path: nil, edit_path: nil, destroy_path: nil)
    @cells        = cells
    @model_id     = model_id
    @show_path    = show_path
    @edit_path    = edit_path
    @destroy_path = destroy_path
  end

  def actions?
    @show_path.present? || @edit_path.present? || @destroy_path.present?
  end

  def action_menu_id
    "options-menu-#{@model_id}"
  end
end