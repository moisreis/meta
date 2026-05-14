# frozen_string_literal: true

# Component responsible for rendering a user avatar representation.
#
# This component generates user initials and enforces a minimal contract for
# objects passed as the user dependency.
#
# @author Moisés Reis

class Modules::AvatarComponent < ApplicationComponent

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # @param user [#first_name, #last_name] An object representing a user.
  # @raise [ArgumentError] If the user object does not respond to required methods.
  def initialize(user:)
    validate_user!(user)
    @user = user
  end

  # ==========================================================================
  # PUBLIC METHODS
  # ==========================================================================

  # Generates a two-letter uppercase string from the user's name.
  #
  # @return [String] The user's initials (e.g., "MR").
  def initials
    "#{@user.first_name.first}#{@user.last_name.first}".upcase
  end

  private

  # ==========================================================================
  # VALIDATION
  # ==========================================================================

  # Ensures the dependency follows the required interface.
  #
  # @param user [Object] The object to validate.
  def validate_user!(user)
    unless user.respond_to?(:first_name) && user.respond_to?(:last_name)
      raise ArgumentError, "User must respond to :first_name and :last_name"
    end
  end
end
