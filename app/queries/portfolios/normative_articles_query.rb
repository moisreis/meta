# frozen_string_literal: true

# Fetches portfolio normative articles with their associated normative
# article in an eager-loaded and reusable form for reporting and UI
# rendering.
#
# @author Moisés Reis

module Portfolios
  class NormativeArticlesQuery
    # @param portfolio [Portfolio]
    # @return [ActiveRecord::Relation<PortfolioNormativeArticle>]
    def self.call(portfolio)
      portfolio.portfolio_normative_articles
               .includes(:normative_article)
    end
  end
end
