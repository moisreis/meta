# Provides user-related service objects and business operations.
#
# This namespace groups service classes responsible for orchestrating
# user-related workflows, validation handling, and persistence logic.
#
# @author Moisés Reis

module Users

  # Handles user update workflows through form-backed validation.
  #
  # This service validates incoming form data, updates an existing user
  # record, and promotes persistence-layer validation errors back to the
  # form object when necessary.
  class UpdateService < Users::BaseService

    # ==========================================================================
    # PUBLIC CLASS METHODS
    # ==========================================================================

    class << self

      # Executes the user update workflow.
      #
      # @param user [User] User entity to be updated.
      # @param params [Hash] Raw user form parameters.
      # @param actor [User] User performing the update operation.
      # @return [Users::BaseService::Result] Structured service result.
      def call(user, params, actor:)
        instance = new(user: user, params: params, actor: actor)
        instance.send(:call)
      end
    end

    private

    # ==========================================================================
    # INITIALIZATION
    # ==========================================================================

    # Initializes the service object.
    #
    # @param user [User] User entity to be updated.
    # @param params [Hash] Raw user form parameters.
    # @param actor [User] User performing the update operation.
    def initialize(user:, params:, actor:)
      @user  = user
      @actor = actor
      @form  = ::UserForm.new(params)
    end

    # ==========================================================================
    # PRIVATE METHODS
    # ==========================================================================

    # Executes the user update workflow.
    #
    # The workflow:
    # - validates the form object
    # - updates the persisted user entity
    # - promotes model validation errors back to the form when necessary
    #
    # @return [Users::BaseService::Result] Structured service result.
    def call
      return failure(@user) unless @form.valid?

      return success(@user) if @user.update(@form.to_model_attributes)

      promote_errors(@user)

      failure(@user)
    end
  end
end
