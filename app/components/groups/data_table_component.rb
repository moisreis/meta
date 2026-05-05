# frozen_string_literal: true

# == Modules::DataTableComponent
#
# Renders a complete, filterable, paginated data table inside a Turbo Frame.
# Encapsulates toolbar controls (clear filters, open filters, add item, export),
# the turbo frame wrapper, column/row rendering, and pagination in one place.
#
# @example Basic usage
#   <%= render Modules::DataTableComponent.new(
#         columns:        [{ label: "Nome", icon: "user" }, { label: "E-mail", icon: "at-sign" }],
#         rows:           @users,
#         turbo_frame_id: "users_table",
#         search_url:     users_path,
#         new_path:       new_user_path,
#         q_object:       @q
#       ) do |row, user| %>
#     <%= row.cell { normalize_title(user.full_name) } %>
#     <%= row.cell { normalize_text(user.email) }     %>
#   <% end %>
#
class Groups::DataTableComponent < ApplicationComponent
  # @param columns        [Array<Hash>] Each hash requires :label; accepts optional :icon and :description.
  # @param rows           [ActiveRecord::Relation, Array] The collection to iterate over.
  # @param turbo_frame_id [String] ID for the Turbo Frame wrapping the table body.
  # @param search_url     [String] URL for filter/clear-filter actions.
  # @param q_object       [Ransack::Search, nil] Ransack search object. Toolbar is hidden when nil.
  # @param new_path       [String, nil] URL for the "Adicionar item" button. Hidden when nil.
  # @param export_url     [String, nil] URL for the CSV/Excel export button. Hidden when nil.
  def initialize(
    columns:,
    rows:,
    turbo_frame_id:,
    search_url:,
    q_object: nil,
    new_path: nil,
    export_url: nil
  )
    @columns        = columns
    @rows           = rows
    @turbo_frame_id = turbo_frame_id
    @search_url     = search_url
    @q_object       = q_object
    @new_path       = new_path
    @export_url     = export_url
  end

  # @return [Integer] Total record count, compatible with Kaminari and plain arrays.
  def total_count
    @rows.respond_to?(:total_count) ? @rows.total_count : @rows.size
  end

  def toolbar?
    @q_object.present?
  end

  def export?
    @export_url.present?
  end

  def new_path?
    @new_path.present?
  end
end