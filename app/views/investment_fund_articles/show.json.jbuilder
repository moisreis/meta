<%#
  VIEW: show.json.jbuilder
  ACTION: InvestmentFundArticlesController#show
  DESCRIPTION: JSON representation of a single InvestmentFundArticle.
  INSTANCE VARIABLES:
    - @investment_fund_article: [InvestmentFundArticle] The record to serialize.
%>
json.partial! "investment_fund_articles/investment_fund_article", investment_fund_article: @investment_fund_article
