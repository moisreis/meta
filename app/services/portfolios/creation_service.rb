# frozen_string_literal: true

# app/services/portfolios/creation_service.rb
#
# Handles the portfolio creation workflow.
#
# Responsibilities:
# - validates form input
# - persists the portfolio aggregate
# - optionally grants shared access
# - promotes persistence errors back into the form
#
# @author Moisés Reis
module Portfolios
  class CreationService < Portfolios::BaseService

    # ===========================================================
    #                         1. ENTRYPOINT
    # ===========================================================

    # @param params [ActionController::Parameters]
    # @param actor [User]
    # @return [Portfolios::BaseService::Result]
    def self.call(params, actor:)
      new(params, actor: actor).send(:call)
    end

    private

    # ===========================================================
    #                       2. INITIALIZATION
    # ===========================================================

    # @param params [ActionController::Parameters]
    # @param actor [User]
    # @return [void]
    def initialize(params, actor:)
      @actor = actor
      @form  = ::PortfolioForm.new(normalized_params(params))
    end

    # ===========================================================
    #                    3. CREATION WORKFLOW
    # ===========================================================

    # @return [Portfolios::BaseService::Result]
    def call
      return failure unless @form.valid?

      portfolio = build_portfolio

      ActiveRecord::Base.transaction do
        portfolio.save!

        grant_permission_if_present(portfolio)
      end

      success(portfolio)
    rescue ActiveRecord::RecordInvalid
      promote_errors(portfolio)

      failure(portfolio)
    end

    # ===========================================================
    #                    4. PORTFOLIO FACTORY
    # ===========================================================

    # @return [Portfolio]
    def build_portfolio
      Portfolio.new(@form.to_model_attributes)
    end

    # ===========================================================
    #                    5. SHARING WORKFLOW
    # ===========================================================

    # @param portfolio [Portfolio]
    # @return [void]
    def grant_permission_if_present(portfolio)
      return if @form.shared_user_id.blank?

      UserPortfolioPermission.find_or_create_by!(
        user_id: @form.shared_user_id,
        portfolio_id: portfolio.id
      ) do |permission|
        permission.permission_level = @form.grant_crud_permission
      end
    end

    # ===========================================================
    #                      6. PARAM NORMALIZATION
    # ===========================================================

    # Prevents ownership spoofing by non-admin users.
    #
    # @param params [ActionController::Parameters]
    # @return [Hash]
    def normalized_params(params)
      attributes = params.to_h.deep_symbolize_keys

      attributes[:user_id] = @actor.id unless @actor.admin?

      attributes
    end
  end
end