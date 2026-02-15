# frozen_string_literal: true

# Helper module for determining which RESTful actions are available for a given model
# Used by the table partial to conditionally render action buttons
module TableHelper
  # Checks if a specific route exists for the given model
  #
  # @param model [ActiveRecord::Base] The model instance to check routes for
  # @param action [Symbol] The action to check (:show, :edit, :destroy)
  # @return [Boolean] true if the route exists, false otherwise
  def route_exists_for?(model, action)
    return false if model.nil?

    case action
    when :show
      polymorphic_path_exists?(model)
    when :edit
      polymorphic_path_exists?(model, action: :edit)
    when :destroy
      polymorphic_path_exists?(model) # destroy uses the same path as show
    else
      false
    end
  rescue NoMethodError, ActionController::UrlGenerationError
    false
  end

  # Checks if any action menu routes exist for the model
  #
  # @param model [ActiveRecord::Base] The model instance to check
  # @return [Boolean] true if at least one action route exists
  def show_action_menu?(model)
    [:show, :edit, :destroy].any? { |action| route_exists_for?(model, action) }
  end

  private

  # Helper method to test if a polymorphic path can be generated
  #
  # @param model [ActiveRecord::Base] The model instance
  # @param options [Hash] Additional options (like action: :edit)
  # @return [Boolean] true if path can be generated
  def polymorphic_path_exists?(model, options = {})
    polymorphic_path(model, options)
    true
  rescue NoMethodError, ActionController::UrlGenerationError
    false
  end
end