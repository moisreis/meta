# frozen_string_literal: true

# app/services/portfolios/deletion_service.rb
#
# Handles the deletion workflow for portfolios.
#
# Encapsulates:
# - destruction rules
# - transactional deletion
# - standardized result handling
#
# @author Moisés Reis
module Portfolios
  class DeletionService < Portfolios::BaseService

    # ===========================================================
    #                         1. ENTRYPOINT
    # ===========================================================

    # @param portfolio [Portfolio]
    # @param actor [User]
    # @return [Portfolios::BaseService::Result]
    def self.call(portfolio, actor:)
      new(portfolio, actor: actor).send(:call)
    end

    private

    # ===========================================================
    #                       2. INITIALIZATION
    # ===========================================================

    # @param portfolio [Portfolio]
    # @param actor [User]
    # @return [void]
    def initialize(portfolio, actor:)
      @portfolio = portfolio
      @actor     = actor
    end

    # ===========================================================
    #                    3. DELETION WORKFLOW
    # ===========================================================

    # @return [Portfolios::BaseService::Result]
    def call
      ActiveRecord::Base.transaction do
        @portfolio.destroy!
      end

      success(@portfolio)
    rescue ActiveRecord::RecordInvalid,
           ActiveRecord::RecordNotDestroyed
      failure(@portfolio)
    end
  end
end