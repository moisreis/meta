# frozen_string_literal: true

# Component responsible for rendering a user avatar representation.
#
# This component renders either:
# - an uploaded Active Storage avatar image
# - fallback user initials when no avatar exists
#
# The component enforces a minimal dependency contract for user-like objects.
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

  # Returns whether the user has an attached avatar image.
  #
  # @return [Boolean] True when an avatar attachment exists.
  def avatar_attached?
    @user.respond_to?(:avatar) &&
      @user.avatar.attached?
  end

  # Returns the processed avatar variant used by the component.
  #
  # @return [ActiveStorage::Variant, nil] Resized avatar image variant.
  def avatar_variant
    return unless avatar_attached?

    @user.avatar.variant(
      resize_to_fill: [28, 28]
    )
  end

  private

  # ==========================================================================
  # VALIDATION
  # ==========================================================================

  # Ensures the dependency follows the required interface.
  #
  # @param user [Object] The object to validate.
  # @return [void]
  # @raise [ArgumentError] If required methods are missing.
  def validate_user!(user)
    unless user.respond_to?(:first_name) &&
           user.respond_to?(:last_name)
      raise ArgumentError,
            "User must respond to :first_name and :last_name"
    end
  end
end