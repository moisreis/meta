# app/services/portfolios/base_service.rb
#
# Provides shared behavior and result handling for
# portfolio-related service objects.
#
# This abstract base class standardizes:
# - Success and failure responses
# - Result object structure
#
# @author Moisés Reis
module Portfolios
  class BaseService

    # ===========================================================
    #                    1. RESULT STRUCTURE
    # ===========================================================

    # Standardized response object returned by
    # portfolio-related service objects.
    #
    # @!attribute [r] success?
    #   @return [Boolean]
    #
    # @!attribute [r] portfolio
    #   @return [Portfolio, nil]
    #
    # @!attribute [r] form
    #   @return [Object, nil]
    Result = Struct.new(
      :success?,
      :portfolio,
      :form,
      keyword_init: true
    )

    private

    # ===========================================================
    #                    2. SUCCESS HELPERS
    # ===========================================================

    # @param portfolio [Portfolio]
    # @return [Result]
    def success(portfolio)
      Result.new(
        success?:  true,
        portfolio: portfolio,
        form:      @form
      )
    end

    # ===========================================================
    #                    3. FAILURE HELPERS
    # ===========================================================

    # @param portfolio [Portfolio, nil]
    # @return [Result]
    def failure(portfolio = nil)
      Result.new(
        success?:  false,
        portfolio: portfolio,
        form:      @form
      )
    end

    # ===========================================================
    #                     4. ERROR PROMOTION
    # ===========================================================

    # Copies validation errors from a model into the current
    # form object.
    #
    # @param model [ActiveModel::Model]
    # @return [void]
    def promote_errors(model)
      model.errors.each do |error|
        @form.errors.add(error.attribute, error.message)
      end
    end
  end
end