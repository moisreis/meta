# frozen_string_literal: true

module FundInvestments

  # Provides shared service helpers and standardized result
  # objects for FundInvestment service workflows.
  #
  # This abstract base service centralizes success/failure
  # response handling and form error propagation across
  # FundInvestment service objects.
  #
  # Responsibilities:
  # - Standardize service result contracts.
  # - Provide reusable success/failure helpers.
  # - Promote model validation errors to form objects.
  # - Encapsulate common service response behavior.
  #
  # Subclasses are expected to expose a `.call` interface
  # and assign an internal `@form` object when validation
  # feedback propagation is required.
  #
  # @author Moisés Reis
  # @abstract Subclass and implement service-specific workflows.
  class BaseService

    # =============================================================
    #                         RESULT OBJECT
    # =============================================================

    # Standardized service response object returned by
    # FundInvestment service workflows.
    #
    # @!attribute [r] success?
    #   @return [Boolean]
    #   Indicates whether the operation completed successfully.
    #
    # @!attribute [r] fund_investment
    #   @return [FundInvestment, nil]
    #   Processed investment instance associated with the operation.
    #
    # @!attribute [r] form
    #   @return [Object, nil]
    #   Form object containing validation state and errors.
    #
    # @!attribute [r] payload
    #   @return [Hash]
    #   Additional contextual service response data.
    Result = Struct.new(
      :success?,
      :fund_investment,
      :form,
      :payload,
      keyword_init: true
    )

    private

    # =============================================================
    #                        RESULT HELPERS
    # =============================================================

    # --- SUCCESS RESPONSES --------------------------------------

    # Builds a successful service result object.
    #
    # @param fund_investment [FundInvestment]
    #   Successfully processed investment instance.
    #
    # @param payload [Hash]
    #   Additional contextual response data.
    #
    # @return [Result]
    #   Successful service response object.
    def success(fund_investment, payload: {})
      Result.new(
        success?: true,
        fund_investment: fund_investment,
        form: @form,
        payload: payload
      )
    end

    # --- FAILURE RESPONSES --------------------------------------

    # Builds a failed service result object.
    #
    # @param fund_investment [FundInvestment, nil]
    #   Investment instance associated with the failure.
    #
    # @param payload [Hash]
    #   Additional contextual response data.
    #
    # @return [Result]
    #   Failed service response object.
    def failure(fund_investment = nil, payload: {})
      Result.new(
        success?: false,
        fund_investment: fund_investment,
        form: @form,
        payload: payload
      )
    end

    # =============================================================
    #                       ERROR PROPAGATION
    # =============================================================

    # --- FORM ERROR PROMOTION -----------------------------------

    # Copies model validation errors into the active
    # form object.
    #
    # This allows service workflows to expose model
    # validation failures consistently through form
    # objects used by controllers and views.
    #
    # @param model [ActiveModel::Model]
    #   Model containing validation errors.
    #
    # @return [void]
    def promote_errors(model)
      model.errors.each do |error|
        @form.errors.add(error.attribute, error.message)
      end
    end
  end
end