# frozen_string_literal: true

# Component responsible for rendering a generic data table with optional
# search, export, and creation toolbar actions.
#
# This component abstracts common table behaviors such as pagination support,
# row rendering, and auxiliary actions (export/new).
#
# @author Moisés Reis

class Groups::DataTableComponent < ApplicationComponent

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # @param columns [Array<Modules::TableColumnComponent>] Column header definitions.
  # @param rows [ActiveRecord::Relation, Array] The collection of records to render.
  # @param turbo_frame_id [String] The ID for the Turbo Frame to enable partial updates.
  # @param search_url [String] The destination URL for the search form.
  # @param q_object [Ransack::Search, nil] The Ransack search object for the toolbar.
  # @param new_path [String, nil] URL for the 'New Record' button.
  # @param export_url [String, nil] URL for the 'Export to CSV/Excel' action.
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

  # ==========================================================================
  # QUERY METHODS
  # ==========================================================================

  # Returns the total number of records, supporting Kaminari-paginated collections.
  # @return [Integer]
  def total_count
    @rows.respond_to?(:total_count) ? @rows.total_count : @rows.size
  end

  # Checks if the search toolbar should be rendered.
  # @return [Boolean]
  def toolbar?
    @q_object.present?
  end

  # Checks if the export action is available.
  # @return [Boolean]
  def export?
    @export_url.present?
  end

  # Checks if the 'New' record action is available.
  # @return [Boolean]
  def new_path?
    @new_path.present?
  end
end
