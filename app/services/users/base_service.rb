# Provides user-related service objects and business operations.
#
# This namespace groups service classes responsible for orchestrating
# user-related workflows, validation handling, and transactional logic.
#
# @author Moisés Reis

module Users

  # Provides shared result handling and error propagation behavior
  # for user service objects.
  #
  # This abstract base service standardizes service response structures
  # and centralizes form error promotion logic across user workflows.
  #
  # @abstract Subclass and implement domain-specific service behavior.
  class BaseService

    # ==========================================================================
    # RESULT OBJECTS
    # ==========================================================================

    # Immutable service result object returned by service operations.
    #
    # @!attribute [r] success?
    #   @return [Boolean] Indicates whether the service operation succeeded.
    #
    # @!attribute [r] user
    #   @return [User, nil] Persisted or processed user entity.
    #
    # @!attribute [r] form
    #   @return [ActiveModel::Model] Form object containing validation state.
    Result = Struct.new(
      :success?,
      :user,
      :form,
      keyword_init: true
    )

    private

    # ==========================================================================
    # RESULT HELPERS
    # ==========================================================================

    # Builds a successful service result.
    #
    # @param user [User] Successfully processed user entity.
    # @return [Result] Successful service result object.
    def success(user)
      Result.new(
        success?: true,
        user: user,
        form: @form
      )
    end

    # Builds a failed service result.
    #
    # @param user [User, nil] User entity associated with the failed operation.
    # @return [Result] Failed service result object.
    def failure(user = nil)
      Result.new(
        success?: false,
        user: user,
        form: @form
      )
    end

    # Promotes model validation errors onto the form object.
    #
    # This method copies validation errors from a persistence model into
    # the service form object to provide unified error presentation.
    #
    # @param model [ActiveModel::Model] Model containing validation errors.
    # @return [void]
    def promote_errors(model)
      model.errors.each do |error|
        @form.errors.add(error.attribute, error.message)
      end
    end
  end
end
