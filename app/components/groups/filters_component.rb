# frozen_string_literal: true

# Component responsible for rendering filter UI blocks for data queries.
#
# This component abstracts filter configuration rendering and supports multiple
# filter types, including date-based and select-based filters.
#
# @author Moisés Reis

class Groups::FiltersComponent < ApplicationComponent

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # @param q_object [Ransack::Search] The search object to build the form.
  # @param search_url [String] The destination URL for the search.
  # @param turbo_frame_id [String] The ID of the frame to be updated.
  # @param filters [Array<Hash>] List of filter definitions (e.g., { label: "Date", attribute: :created_at_gteq, type: :date }).
  def initialize(q_object:, search_url:, turbo_frame_id:, filters:)
    @q_object       = q_object
    @search_url     = search_url
    @turbo_frame_id = turbo_frame_id
    @filters        = filters
  end

  # ==========================================================================
  # QUERY METHODS
  # ==========================================================================

  # Determines if a specific filter definition is date-based.
  # @param filter [Hash]
  # @return [Boolean]
  def date_filter?(filter)
    filter[:type] == :date
  end
end
