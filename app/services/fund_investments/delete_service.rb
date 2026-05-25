# frozen_string_literal: true

module FundInvestments

  # Deletes FundInvestment records through a transactional
  # and authorization-aware workflow.
  #
  # This service encapsulates access validation,
  # transactional deletion, and standardized result
  # handling for investment removal operations.
  #
  # Responsibilities:
  # - Enforce deletion authorization rules.
  # - Execute transactional destruction workflows.
  # - Expose standardized success/failure responses.
  # - Surface validation and persistence failures.
  #
  # This service does NOT implement controller-level
  # HTTP response behavior.
  #
  # @author Moisés Reis
  class DeleteService < FundInvestments::BaseService

    # =============================================================
    #                          ENTRYPOINT
    # =============================================================

    # Executes the fund investment deletion workflow.
    #
    # @param fund_investment [FundInvestment]
    #   Investment targeted for deletion.
    #
    # @param actor [User]
    #   Authenticated user performing the operation.
    #
    # @return [FundInvestments::BaseService::Result]
    #   Standardized service response object.
    def self.call(fund_investment, actor:)
      new(fund_investment, actor: actor).send(:call)
    end

    private

    # =============================================================
    #                         INITIALIZATION
    # =============================================================

    # Initializes the deletion workflow context.
    #
    # @param fund_investment [FundInvestment]
    #   Investment targeted for deletion.
    #
    # @param actor [User]
    #   Authenticated user performing the operation.
    #
    # @return [void]
    def initialize(fund_investment, actor:)
      @fund_investment = fund_investment
      @actor = actor
    end

    # =============================================================
    #                       DELETION WORKFLOW
    # =============================================================

    # Executes the transactional deletion workflow.
    #
    # Authorization checks and persistence guarantees
    # are coordinated within a database transaction.
    #
    # @return [FundInvestments::BaseService::Result]
    #   Service operation result.
    #
    # @raise [ActiveRecord::RecordInvalid]
    #   Raised internally when authorization validation fails.
    #
    # @raise [ActiveRecord::RecordNotDestroyed]
    #   Raised when deletion persistence fails.
    def call
      ActiveRecord::Base.transaction do
        validate_access!

        @fund_investment.destroy!
      end

      success(@fund_investment)
    rescue ActiveRecord::RecordInvalid,
           ActiveRecord::RecordNotDestroyed
      failure(@fund_investment)
    end

    # =============================================================
    #                         AUTHORIZATION
    # =============================================================

    # Validates whether the current actor has permission
    # to delete the target investment.
    #
    # Administrators bypass portfolio ownership checks.
    #
    # @return [void]
    #
    # @raise [ActiveRecord::RecordInvalid]
    #   Raised when the actor lacks deletion permission.
    def validate_access!
      return if @actor.admin?

      return if Portfolio.accessible_to(@actor).exists?(
        id: @fund_investment.portfolio_id
      )

      @fund_investment.errors.add(
        :base,
        :forbidden
      )

      raise ActiveRecord::RecordInvalid, @fund_investment
    end
  end
end