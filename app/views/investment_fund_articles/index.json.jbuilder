<%#
  VIEW: index.json.jbuilder
  ACTION: InvestmentFundArticlesController#index
  DESCRIPTION: JSON collection of investment fund articles.
  INSTANCE VARIABLES:
    - @investment_fund_articles: [Array<InvestmentFundArticle>] The collection to serialize.
%>
json.array! @investment_fund_articles, partial: "investment_fund_articles/investment_fund_article", as: :investment_fund_article
