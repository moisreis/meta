# frozen_string_literal: true

# app/services/portfolios/update_service.rb
#
# Handles the portfolio update workflow.
#
# Responsibilities:
# - validates submitted form input
# - updates the portfolio aggregate
# - manages sharing permissions
# - promotes persistence errors back into the form
#
# @author Moisés Reis
module Portfolios
  class UpdateService < Portfolios::BaseService

    # ===========================================================
    #                         1. ENTRYPOINT
    # ===========================================================

    # @param portfolio [Portfolio]
    # @param params [ActionController::Parameters]
    # @param actor [User]
    # @return [Portfolios::BaseService::Result]
    def self.call(portfolio, params, actor:)
      new(portfolio, params, actor: actor).send(:call)
    end

    private

    # ===========================================================
    #                       2. INITIALIZATION
    # ===========================================================

    # @param portfolio [Portfolio]
    # @param params [ActionController::Parameters]
    # @param actor [User]
    # @return [void]
    def initialize(portfolio, params, actor:)
      @portfolio = portfolio
      @actor     = actor
      @form      = ::PortfolioForm.new(normalized_params(params))
    end

    # ===========================================================
    #                     3. UPDATE WORKFLOW
    # ===========================================================

    # @return [Portfolios::BaseService::Result]
    def call
      return failure(@portfolio) unless @form.valid?

      ActiveRecord::Base.transaction do
        @portfolio.update!(@form.to_model_attributes)

        grant_permission_if_present
      end

      success(@portfolio)
    rescue ActiveRecord::RecordInvalid
      promote_errors(@portfolio)

      failure(@portfolio)
    end

    # ===========================================================
    #                    4. SHARING WORKFLOW
    # ===========================================================

    # @return [void]
    def grant_permission_if_present
      return if @form.shared_user_id.blank?

      UserPortfolioPermission.find_or_create_by!(
        user_id: @form.shared_user_id,
        portfolio_id: @portfolio.id
      ) do |permission|
        permission.permission_level = @form.grant_crud_permission
      end
    end

    # ===========================================================
    #                     5. PARAM NORMALIZATION
    # ===========================================================

    # Prevents unauthorized ownership reassignment.
    #
    # @param params [ActionController::Parameters]
    # @return [Hash]
    def normalized_params(params)
      attributes = params.to_h.deep_symbolize_keys

      attributes[:user_id] = @portfolio.user_id unless @actor.admin?

      attributes
    end
  end
end