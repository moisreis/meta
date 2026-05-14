# Provides user-related service objects and business operations.
#
# This namespace groups service classes responsible for orchestrating
# user-related workflows, validation handling, and transactional logic.
#
# @author Moisés Reis

module Users

  # Handles user deletion workflows.
  #
  # This service encapsulates user removal behavior and standardizes
  # success and failure result handling for deletion operations.
  class DeletionService < Users::BaseService

    # ==========================================================================
    # PUBLIC CLASS METHODS
    # ==========================================================================

    class << self

      # Executes the user deletion workflow.
      #
      # @param user [User] User entity to be deleted.
      # @param actor [User] User performing the deletion operation.
      # @return [Users::BaseService::Result] Structured service result.
      def call(user, actor:)
        new(user: user, actor: actor).send(:call)
      end
    end

    private

    # ==========================================================================
    # INITIALIZATION
    # ==========================================================================

    # Initializes the service object.
    #
    # @param user [User] User entity to be deleted.
    # @param actor [User] User performing the deletion operation.
    def initialize(user:, actor:)
      @user  = user
      @actor = actor
    end

    # ==========================================================================
    # PRIVATE METHODS
    # ==========================================================================

    # Executes the user deletion workflow.
    #
    # @return [Users::BaseService::Result] Structured service result.
    def call
      return failure(@user) unless @user.destroy

      success(@user)
    end
  end
end
