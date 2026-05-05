# Provides helper methods for rendering structured navigation sections
# based on a given ActiveRecord model and its associated routes.
#
# This helper delegates item construction to {NavItemsBuilder} and
# rendering concerns to {NavPresenter}, enforcing separation of concerns
# between data preparation and view presentation.
#
# The generated navigation section typically includes:
# - An index link (e.g., "All Users")
# - An optional "new" resource link (e.g., "New User")
# - Custom icons and paths when provided
#
# TABLE OF CONTENTS:
#   1. Public Methods
#
# @author Moisés Reis
module NavHelper
  # =============================================================
  #                         1. PUBLIC METHODS
  # =============================================================

  # Renders a navigation section for a given model class.
  #
  # This method dynamically builds a navigation structure using the model's
  # naming conventions and optional overrides. It delegates:
  # - Item construction to {NavItemsBuilder}
  # - Rendering to {NavPresenter}
  #
  # @param model_class [Class] The ActiveRecord model class (e.g., User, Post).
  # @param plural [String, nil] Optional custom plural label for the section.
  #   Defaults to the model's humanized plural name.
  # @param icons [Hash] Optional icon mappings for navigation items.
  # @option icons [String, Symbol] :index Icon identifier for the index link.
  # @option icons [String, Symbol] :new Icon identifier for the "new" link.
  # @param index_path [String, nil] Optional override for the index route path.
  #   If nil, defaults to the standard Rails route helper.
  # @param new_path [String, nil] Optional override for the "new" route path.
  #   If nil, defaults to the standard Rails route helper.
  # @param show_new [Boolean] Whether to include the "new" resource link.
  #   Defaults to true.
  #
  # @return [String] HTML-safe string containing the rendered navigation section.
  #
  # @raise [ArgumentError] If model_class does not respond to ActiveModel naming.
  def render_nav_section_for(model_class, plural: nil, icons: {}, index_path: nil, new_path: nil, show_new: true)
    unless model_class.respond_to?(:model_name)
      raise ArgumentError, "model_class must respond to :model_name"
    end

    plural ||= model_class.model_name.human(count: 2)

    resources = model_class.model_name.route_key
    nav_id = "nav-#{resources}"

    items = NavItemsBuilder.new(self).call(
      model_class,
      icons: icons,
      index_path: index_path,
      new_path: new_path,
      show_new: show_new
    )

    presenter = NavPresenter.new(self)
    presenter.render(label: plural, nav_id: nav_id, items: items)
  end
end