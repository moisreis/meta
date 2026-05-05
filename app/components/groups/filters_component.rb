# frozen_string_literal: true

# == Modules::FiltersComponent
#
# Renders a sliding sidebar containing Ransack-powered search filter fields.
# Accepts an arbitrary list of filter definitions and renders each one using
# the appropriate input component. Designed to work in tandem with
# Modules::DataTableComponent via a shared turbo_frame_id.
#
# @example Usage
#   <%= render Modules::FiltersComponent.new(
#         q_object:       @q,
#         search_url:     users_path,
#         turbo_frame_id: "users_table",
#         filters: [
#           { key: :first_name_cont, label: "Nome",   placeholder: "Maria", icon_name: "user" },
#           { key: :email_cont,      label: "E-mail",  placeholder: "email@exemplo.com", icon_name: "at-sign" }
#         ]
#       ) %>
#
# Filter hash keys:
#   @option filter [Symbol]  :key          Ransack predicate key (e.g. :first_name_cont).
#   @option filter [String]  :label        Human-readable label for the field.
#   @option filter [String]  :description  Helper text shown below the input.
#   @option filter [String]  :placeholder  Input placeholder text.
#   @option filter [String]  :icon_name    SVG icon name (without extension).
#   @option filter [Symbol]  :type         :date for date fields; omit for standard text.
#   @option filter [Boolean] :cnpj_mask    Activates CNPJ mask on the input.
#   @option filter [Boolean] :currency_mask Activates currency mask on the input.
#
class Groups::FiltersComponent < ApplicationComponent
  # @param q_object       [Ransack::Search] The Ransack search object.
  # @param search_url     [String] Form action URL; also used for the clear link.
  # @param turbo_frame_id [String] Turbo Frame ID to target on form submission.
  # @param filters        [Array<Hash>] Filter field definitions (see above).
  def initialize(q_object:, search_url:, turbo_frame_id:, filters:)
    @q_object       = q_object
    @search_url     = search_url
    @turbo_frame_id = turbo_frame_id
    @filters        = filters
  end

  # @return [Boolean]
  def date_filter?(filter)
    filter[:type] == :date
  end
end