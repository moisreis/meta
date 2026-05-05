# frozen_string_literal: true

class Groups::TableListComponent < ApplicationComponent
  renders_many :columns, Modules::TableColumnComponent
  renders_many :rows,    Modules::TableRowComponent

  def initialize(title: nil, description: nil, action: nil, collection: [])
    @title       = title
    @description = description
    @action      = action
    @collection  = collection
  end

  def empty?
    @collection.none?
  end

  def row_count
    @collection.size
  end
end