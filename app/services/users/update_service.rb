# app/services/users/update_service.rb
#
# Handles the update workflow for user accounts.
#
# This service validates submitted form data, updates the
# target user record, and promotes persistence errors back
# into the form object.
#
# @author Moisés Reis
module Users
  class UpdateService < Users::BaseService

    # ===========================================================
    #                         1. ENTRYPOINT
    # ===========================================================

    # Executes the user update workflow.
    #
    # @param user [User]
    #   The user record being updated.
    #
    # @param params [ActionController::Parameters]
    #
    # @param actor [User]
    #   The authenticated user performing the action.
    #
    # @return [Users::BaseService::Result]
    def self.call(user, params, actor:)
      instance = new(user, params, actor: actor)

      instance.send(:call)
    end

    private

    # ===========================================================
    #                        2. INITIALIZATION
    # ===========================================================

    # Initializes the service state and form object.
    #
    # @param user [User]
    # @param params [ActionController::Parameters]
    # @param actor [User]
    #
    # @return [void]
    def initialize(user, params, actor:)
      @user  = user
      @actor = actor
      @form  = ::UserForm.new(params)
    end

    # ===========================================================
    #                      3. UPDATE WORKFLOW
    # ===========================================================

    # Validates the form and attempts to update the user.
    #
    # @return [Users::BaseService::Result]
    def call
      return failure(@user) unless @form.valid?

      return success(@user) if @user.update(@form.to_model_attributes)

      promote_errors(@user)

      failure(@user)
    end
  end
end