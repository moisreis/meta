# app/queries/portfolios/compliance_report_query.rb
#
# Builds the compliance report array comparing actual allocation percentages
# against the normative article targets and limits.
module Portfolios
  class ComplianceReportQuery
    def self.call(portfolio, normative_data)
      portfolio.portfolio_normative_articles
               .includes(:normative_article)
               .map do |pna|
        actual = normative_data[pna.normative_article.article_number] || 0
        {
          article: pna.normative_article.article_number,
          actual:  actual.to_f,
          min:     pna.minimum_target.to_f,
          max:     pna.maximum_target.to_f,
          target:  pna.benchmark_target.to_f,
          status:  (actual >= pna.minimum_target && actual <= pna.maximum_target) ? "success" : "danger"
        }
      end
    end
  end
end