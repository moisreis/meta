# app/services/users/base_service.rb
#
# Provides shared behavior and result handling for
# user-related service objects.
#
# This abstract base class standardizes:
# - Success and failure responses
# - Form error propagation
# - Result object structure
#
# @author Moisés Reis
module Users
  class BaseService

    # ===========================================================
    #                    1. RESULT STRUCTURE
    # ===========================================================

    # Standardized response object returned by
    # user-related service objects.
    #
    # @!attribute [r] success?
    #   @return [Boolean]
    #
    # @!attribute [r] user
    #   @return [User, nil]
    #
    # @!attribute [r] form
    #   @return [Object, nil]
    Result = Struct.new(
      :success?,
      :user,
      :form,
      keyword_init: true
    )

    private

    # ===========================================================
    #                    2. SUCCESS HELPERS
    # ===========================================================

    # Builds a successful service response.
    #
    # @param user [User]
    #
    # @return [Result]
    def success(user)
      Result.new(
        success?: true,
        user: user,
        form: @form
      )
    end

    # ===========================================================
    #                    3. FAILURE HELPERS
    # ===========================================================

    # Builds a failed service response.
    #
    # @param user [User, nil]
    #
    # @return [Result]
    def failure(user = nil)
      Result.new(
        success?: false,
        user: user,
        form: @form
      )
    end

    # ===========================================================
    #                     4. ERROR PROMOTION
    # ===========================================================

    # Copies validation errors from a model into the current
    # form object.
    #
    # @param model [ActiveModel::Model]
    #
    # @return [void]
    def promote_errors(model)
      model.errors.each do |error|
        @form.errors.add(error.attribute, error.message)
      end
    end
  end
end