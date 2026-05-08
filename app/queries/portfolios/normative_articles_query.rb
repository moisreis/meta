# app/queries/portfolios/normative_articles_query.rb
# frozen_string_literal: true

module Portfolios
  ##
  # Fetches portfolio normative articles with their associated normative article
  # in an eager-loaded and reusable form for reporting and UI rendering.
  #
  class NormativeArticlesQuery
    class << self
      # @param portfolio [Portfolio]
      # @return [ActiveRecord::Relation<PortfolioNormativeArticle>]
      def call(portfolio)
        portfolio.portfolio_normative_articles
                 .includes(:normative_article)
      end
    end
  end
end