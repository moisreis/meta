# frozen_string_literal: true

class Modules::TableColumnComponent < ApplicationComponent

  def initialize(label:, icon: nil, description: nil)
    @label       = label
    @icon        = icon
    @description = description
  end

  def icon?
    @icon.present?
  end

  def description?
    @description.present?
  end
end