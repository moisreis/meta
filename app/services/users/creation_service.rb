# app/services/users/creation_service.rb
#
# Handles the creation workflow for user accounts.
#
# This service validates form input, persists the user record,
# and promotes persistence errors back into the form object.
#
# @author Moisés Reis
module Users
  class CreationService < Users::BaseService

    # ===========================================================
    #                         1. ENTRYPOINT
    # ===========================================================

    # Executes the user creation workflow.
    #
    # @param params [ActionController::Parameters]
    # @param actor [User]
    #   The authenticated user performing the action.
    #
    # @return [Users::BaseService::Result]
    def self.call(params, actor:)
      instance = new(params, actor: actor)

      instance.send(:call)
    end

    private

    # ===========================================================
    #                        2. INITIALIZATION
    # ===========================================================

    # Initializes the service state and form object.
    #
    # @param params [ActionController::Parameters]
    # @param actor [User]
    #
    # @return [void]
    def initialize(params, actor:)
      @actor = actor
      @form  = ::UserForm.new(params)
    end

    # ===========================================================
    #                     3. CREATION WORKFLOW
    # ===========================================================

    # Validates the form and attempts to persist the user.
    #
    # @return [Users::BaseService::Result]
    def call
      return failure unless @form.valid?

      user = User.new(@form.to_model_attributes)

      return success(user) if user.save

      promote_errors(user)

      failure(user)
    end
  end
end