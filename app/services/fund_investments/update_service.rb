# frozen_string_literal: true

module FundInvestments

  # Updates an existing {FundInvestment} through validated
  # form-driven persistence workflows.
  #
  # This service coordinates update operations for
  # fund investments while enforcing authorization,
  # transactional integrity, and validation consistency.
  #
  # Responsibilities:
  # - Normalize incoming controller parameters.
  # - Validate update payloads through {FundInvestmentForm}.
  # - Enforce portfolio access restrictions.
  # - Persist validated investment updates transactionally.
  # - Promote persistence-layer validation errors back to the form.
  # - Return standardized result objects.
  #
  # This service does NOT implement controller behavior
  # or direct authorization policies.
  #
  # Inherits shared success/failure result helpers from
  # {FundInvestments::BaseService}.
  #
  # @author Moisés Reis  
  class UpdateService < FundInvestments::BaseService

    # =============================================================
    #                      PUBLIC INTERFACE
    # =============================================================

    # Executes the fund investment update workflow.
    #
    # @param fund_investment [FundInvestment]
    #   Existing investment being updated.
    #
    # @param params [ActionController::Parameters, Hash]
    #   Raw update parameters received from the controller layer.
    #
    # @param actor [User]
    #   Authenticated user performing the operation.
    #
    # @return [FundInvestments::BaseService::Result]
    #   Standardized update operation result.
    def self.call(fund_investment, params, actor:)
      new(
        fund_investment,
        params,
        actor: actor
      ).send(:call)
    end

    # =============================================================
    #                        INITIALIZATION
    # =============================================================

    private

    # Initializes the update workflow context.
    #
    # @param fund_investment [FundInvestment]
    #   Existing investment being updated.
    #
    # @param params [ActionController::Parameters, Hash]
    #   Raw incoming update parameters.
    #
    # @param actor [User]
    #   Authenticated user performing the operation.
    #
    # @return [void]
    def initialize(fund_investment, params, actor:)
      @fund_investment = fund_investment
      @actor = actor

      @form = ::FundInvestmentForm.new(
        normalized_params(params)
      )
    end

    # =============================================================
    #                           EXECUTION
    # =============================================================

    # Executes the transactional update workflow.
    #
    # Validation failures immediately return a failure result
    # without attempting persistence.
    #
    # @return [FundInvestments::BaseService::Result]
    #   Success or failure result object.
    #
    # @raise [ActiveRecord::RecordInvalid]
    #   Raised internally when persistence validation fails.
    def call
      return failure(@fund_investment) unless @form.valid?

      ActiveRecord::Base.transaction do
        validate_portfolio_access!

        @fund_investment.update!(
          @form.to_model_attributes
        )
      end

      success(@fund_investment)
    rescue ActiveRecord::RecordInvalid
      promote_errors(@fund_investment)

      failure(@fund_investment)
    end

    # =============================================================
    #                    PERSISTENCE WORKFLOWS
    # =============================================================

    # --- PORTFOLIO ACCESS VALIDATION -----------------------------

    # Validates whether the authenticated actor has permission
    # to associate the investment with the target portfolio.
    #
    # Administrative users bypass this validation.
    #
    # @raise [ActiveRecord::RecordInvalid]
    #   Raised when the actor lacks portfolio access permission.
    #
    # @return [void]
    def validate_portfolio_access!
      return if @actor.admin?

      target_portfolio_id =
        @form.to_model_attributes[:portfolio_id]

      return if Portfolio.accessible_to(@actor).exists?(
        id: target_portfolio_id
      )

      @fund_investment.errors.add(
        :portfolio_id,
        :invalid
      )

      raise ActiveRecord::RecordInvalid, @fund_investment
    end

    # =============================================================
    #                  PARAMETER NORMALIZATION
    # =============================================================

    # Normalizes incoming parameters into a symbolized hash
    # compatible with form object expectations.
    #
    # @param params [ActionController::Parameters, Hash]
    #   Raw incoming controller parameters.
    #
    # @return [Hash]
    #   Deep-symbolized normalized parameter hash.
    def normalized_params(params)
      params.to_h.deep_symbolize_keys
    end
  end
end