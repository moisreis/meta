<%#
  PARTIAL: _investment_fund_article.json.jbuilder
  DESCRIPTION: JSON partial for a single InvestmentFundArticle record.
               Exposes id, timestamps, and a direct URL.
  LOCAL VARIABLES:
    - investment_fund_article: [InvestmentFundArticle] The record to serialize.
%>
json.extract! investment_fund_article, :id, :created_at, :updated_at
json.url investment_fund_article_url(investment_fund_article, format: :json)
