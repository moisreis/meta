# Provides user-related service objects and business operations.
#
# This namespace groups service classes responsible for orchestrating
# user-related workflows, validation handling, and transactional logic.
#
# @author Moisés Reis

module Users

  # Handles user creation workflows through form-backed validation.
  #
  # This service validates incoming form data, builds a user entity,
  # persists the record, and promotes persistence-layer validation errors
  # back to the form object when necessary.
  class CreationService < Users::BaseService

    # ==========================================================================
    # PUBLIC CLASS METHODS
    # ==========================================================================

    class << self

      # Executes the user creation workflow.
      #
      # @param params [Hash] Raw user form parameters.
      # @param actor [User] User performing the creation operation.
      # @return [Users::BaseService::Result] Structured service result.
      def call(params, actor:)
        instance = new(params, actor: actor)
        instance.send(:call)
      end
    end

    private

    # ==========================================================================
    # INITIALIZATION
    # ==========================================================================

    # Initializes the service object.
    #
    # @param params [Hash] Raw user form parameters.
    # @param actor [User] User performing the creation operation.
    def initialize(params, actor:)
      @actor = actor
      @form  = ::UserForm.new(params)
    end

    # ==========================================================================
    # PRIVATE METHODS
    # ==========================================================================

    # Executes the user creation workflow.
    #
    # The workflow:
    # - validates the form object
    # - builds a user entity
    # - persists the user record
    # - promotes model validation errors back to the form when necessary
    #
    # @return [Users::BaseService::Result] Structured service result.
    def call
      return failure unless @form.valid?

      user = User.new(@form.to_model_attributes)

      return success(user) if user.save

      promote_errors(user)

      failure(user)
    end
  end
end
