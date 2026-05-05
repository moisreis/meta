# app/services/nav_items_builder.rb

# Builds navigation item structures for CRUD modules.
#
# Responsibilities:
# - Derive route names from ActiveRecord models
# - Build navigation item hashes for presenters/views
# - Support optional overrides for paths and icons
#
# No view rendering logic is included here.
#
# TABLE OF CONTENTS:
#   1. Constants & Configuration
#   2. Initialization
#   3. Public Interface
#   4. Private Builders
#
class NavItemsBuilder

  # =============================================================
  # 1. CONSTANTS & CONFIGURATION
  # =============================================================

  DEFAULT_ICONS = {
    index: "wallet.svg",
    new: "plus.svg"
  }.freeze

  # =============================================================
  # 2. INITIALIZATION
  # =============================================================

  # @param view_context [ActionView::Base]
  def initialize(view_context)
    @view = view_context
  end

  # =============================================================
  # 3. PUBLIC INTERFACE
  # =============================================================

  # @param model_class [Class<ActiveRecord::Base>]
  # @param icons [Hash]
  # @param index_path [String, nil]
  # @param new_path [String, nil]
  # @param show_new [Boolean]
  # @return [Array<Hash>]
  def call(model_class, icons: {}, index_path: nil, new_path: nil, show_new: true)
    icon_set = DEFAULT_ICONS.merge(icons.symbolize_keys)

    [
      index_item(model_class, icon_set, index_path),
      *(show_new ? [new_item(model_class, icon_set, new_path)] : [])
    ]
  end

  private

  # =============================================================
  # 4a. INDEX ITEM
  # =============================================================

  def index_item(model_class, icon_set, index_path)
    resource = model_class.model_name.route_key

    {
      icon: icon_set.fetch(:index),
      text: "Ver todos",
      path: index_path || @view.public_send("#{resource}_path")
    }
  end

  # =============================================================
  # 4b. NEW ITEM
  # =============================================================

  def new_item(model_class, icon_set, new_path)
    resource = model_class.model_name.singular_route_key

    {
      icon: icon_set.fetch(:new),
      text: "Adicionar novo",
      path: new_path || @view.public_send("new_#{resource}_path")
    }
  end
end
