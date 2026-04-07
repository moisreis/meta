# frozen_string_literal: true

# == TableHelper
#
# @author Moisés Reis
# @project Meta Investimentos
# @added 04/06/2026
# @package Meta
# @category Helpers
#
# @description
#   Provides utility methods for determining the availability of RESTful actions
#   for ActiveRecord models. It is primarily used by table partials to
#   conditionally render action buttons and menus based on route existence.
#
# @example Checking if an edit action is valid
#   route_exists_for?(@user, :edit)
#   # => true
#
module TableHelper
  # == route_exists_for?
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Validation
  #
  # @description
  #   Checks if a specific RESTful route (show, edit, or destroy) is defined
  #   and accessible for a given model instance.
  #
  # @param model [ActiveRecord::Base, nil] The model instance to evaluate
  # @param action [Symbol] The action to check (:show, :edit, :destroy)
  # @return [Boolean] True if the route is valid and can be generated
  #
  # @example
  #   route_exists_for?(investment, :show)
  #   # => true
  #
  def route_exists_for?(model, action)
    return false if model.nil?

    case action
    when :show
      polymorphic_path_exists?(model)
    when :edit
      polymorphic_path_exists?(model, action: :edit)
    when :destroy
      # Destroy typically uses the same path as 'show' but with a different HTTP verb
      polymorphic_path_exists?(model)
    else
      false
    end
  rescue NoMethodError, ActionController::UrlGenerationError
    false
  end

  # == show_action_menu?
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Determines if an action menu should be rendered by checking if at least
  #   one of the standard CRUD routes exists for the provided model.
  #
  # @param model [ActiveRecord::Base] The model instance to check
  # @return [Boolean] True if any action route (show, edit, or destroy) exists
  #
  # @see #route_exists_for?
  #
  def show_action_menu?(model)
    %i[show edit destroy].any? { |action| route_exists_for?(model, action) }
  end

  private

  # == polymorphic_path_exists?
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Internal
  #
  # @description
  #   Attempts to generate a polymorphic path to verify its existence.
  #   Swallows generation errors to return a boolean state.
  #
  # @param model [ActiveRecord::Base] The model instance
  # @param options [Hash] Additional routing options (default: {})
  # @return [Boolean] True if the path was successfully generated
  #
  def polymorphic_path_exists?(model, options = {})
    polymorphic_path(model, options)
    true
  rescue NoMethodError, ActionController::UrlGenerationError
    false
  end
end
