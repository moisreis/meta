# === investment_fund_article
#
# @author Moisés Reis
# @added 12/4/2025
# @package Meta
# @description This class links a specific investment fund with a regulatory or
#              normative article. It acts as a junction table, creating a
#              many-to-many relationship between **InvestmentFund** and
#              **NormativeArticle** models.
# @category Model
#
# Usage:: - *[What]* This model keeps track of which specific legal or regulatory
#           rules apply to a particular investment fund.
#         - *[How]* It achieves this by holding the foreign keys for both the
#           **InvestmentFund** and the **NormativeArticle** records.
#         - *[Why]* It is necessary to manage the complex relationship where one
#           fund can be subject to many articles, and one article can
#           apply to many different funds.
#
# Attributes:: - *[investment_fund_id]* @integer - The identifier that links to
#                the specific investment fund record.
#              - *[normative_article_id]* @integer - The identifier that links to
#                the specific regulatory article.
#
class InvestmentFundArticle < ApplicationRecord

  # Explanation:: This line establishes a many-to-one relationship, stating that
  #               every instance of an investment fund article belongs to
  #               a single investment fund record.
  belongs_to :investment_fund

  # Explanation:: This line establishes the second many-to-one relationship,
  #               indicating that each article record belongs to a single
  #               normative article that governs it.
  belongs_to :normative_article
end