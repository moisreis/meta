# frozen_string_literal: true

# app/services/users/deletion_service.rb
#
# Handles the deletion workflow for user accounts.
#
# This service encapsulates record destruction logic and
# standardizes success and failure responses.
#
# @author Moisés Reis
module Users
  class DeletionService < Users::BaseService

    # ===========================================================
    #                         1. ENTRYPOINT
    # ===========================================================

    # Executes the user deletion workflow.
    #
    # @param user [User]
    #   The user record being deleted.
    #
    # @param actor [User]
    #   The authenticated user performing the action.
    #
    # @return [Users::BaseService::Result]
    def self.call(user, actor:)
      new(user, actor: actor).send(:call)
    end

    private

    # ===========================================================
    #                        2. INITIALIZATION
    # ===========================================================

    # Initializes the service state.
    #
    # @param user [User]
    # @param actor [User]
    #
    # @return [void]
    def initialize(user, actor:)
      @user  = user
      @actor = actor
    end

    # ===========================================================
    #                     3. DELETION WORKFLOW
    # ===========================================================

    # Attempts to permanently delete the user record.
    #
    # @return [Users::BaseService::Result]
    def call
      return failure(@user) unless @user.destroy

      success(@user)
    end
  end
end