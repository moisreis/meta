# frozen_string_literal: true

module FundInvestments

  # Creates new FundInvestment records through a validated
  # service-oriented workflow.
  #
  # This service encapsulates creation validation,
  # authorization checks, transactional persistence,
  # and standardized response handling for fund
  # investment creation operations.
  #
  # Responsibilities:
  # - Normalize incoming parameters.
  # - Validate form input consistency.
  # - Build FundInvestment entities.
  # - Enforce portfolio access authorization.
  # - Persist investments transactionally.
  # - Propagate validation errors to form objects.
  #
  # This service does NOT implement controller concerns
  # or direct HTTP response behavior.
  #
  # @author Moisés Reis
  class CreationService < FundInvestments::BaseService

    # =============================================================
    #                          ENTRYPOINT
    # =============================================================

    # Executes the fund investment creation workflow.
    #
    # @param params [ActionController::Parameters, Hash]
    #   Raw investment creation parameters.
    #
    # @param actor [User]
    #   Authenticated user performing the operation.
    #
    # @return [FundInvestments::BaseService::Result]
    #   Standardized service response object.
    def self.call(params, actor:)
      new(params, actor: actor).send(:call)
    end

    private

    # =============================================================
    #                         INITIALIZATION
    # =============================================================

    # Initializes the creation service workflow.
    #
    # Parameters are normalized before being assigned
    # to the form object.
    #
    # @param params [ActionController::Parameters, Hash]
    #   Raw investment creation parameters.
    #
    # @param actor [User]
    #   Authenticated user performing the operation.
    #
    # @return [void]
    def initialize(params, actor:)
      @actor = actor

      @form = ::FundInvestmentForm.new(
        normalized_params(params)
      )
    end

    # =============================================================
    #                       CREATION WORKFLOW
    # =============================================================

    # Executes the complete investment creation flow.
    #
    # Validation, authorization, persistence,
    # and transactional guarantees are coordinated
    # through this workflow.
    #
    # @return [FundInvestments::BaseService::Result]
    #   Service operation result.
    #
    # @raise [ActiveRecord::RecordInvalid]
    #   Raised internally when persistence validation fails.
    def call
      return failure unless @form.valid?

      fund_investment = build_fund_investment

      ActiveRecord::Base.transaction do
        validate_portfolio_access!(fund_investment)

        fund_investment.save!
      end

      success(fund_investment)
    rescue ActiveRecord::RecordInvalid
      promote_errors(fund_investment)

      failure(fund_investment)
    end

    # =============================================================
    #                        ENTITY BUILDING
    # =============================================================

    # Builds a FundInvestment entity from validated
    # form attributes.
    #
    # @return [FundInvestment]
    #   Non-persisted investment entity.
    def build_fund_investment
      FundInvestment.new(
        @form.to_model_attributes
      )
    end

    # =============================================================
    #                         AUTHORIZATION
    # =============================================================

    # Validates whether the current actor has permission
    # to create investments within the target portfolio.
    #
    # Administrators bypass portfolio ownership checks.
    #
    # @param fund_investment [FundInvestment]
    #   Investment entity being persisted.
    #
    # @return [void]
    #
    # @raise [ActiveRecord::RecordInvalid]
    #   Raised when the actor lacks portfolio access.
    def validate_portfolio_access!(fund_investment)
      return if @actor.admin?

      return if Portfolio.accessible_to(@actor).exists?(
        id: fund_investment.portfolio_id
      )

      fund_investment.errors.add(
        :portfolio_id,
        :invalid
      )

      raise ActiveRecord::RecordInvalid, fund_investment
    end

    # =============================================================
    #                     PARAMETER NORMALIZATION
    # =============================================================

    # Normalizes incoming parameters into a symbolized hash.
    #
    # @param params [ActionController::Parameters, Hash]
    #   Raw request parameters.
    #
    # @return [Hash]
    #   Deep-symbolized parameter hash.
    def normalized_params(params)
      params.to_h.deep_symbolize_keys
    end
  end
end