# === portfolio_normative_article.rb
#
# Description:: Join model linking a Portfolio to a NormativeArticle.
#               Stores the portfolio-specific benchmark, minimum and maximum
#               targets that will be compared against the article's own targets
#               for compliance reporting.
#
class PortfolioNormativeArticle < ApplicationRecord

  belongs_to :portfolio
  belongs_to :normative_article

  validates :normative_article_id, uniqueness: { scope: :portfolio_id,
    message: "already attached to this portfolio" }

  validates :benchmark_target, numericality: {
    greater_than_or_equal_to: 0, less_than_or_equal_to: 1000
  }, allow_nil: true

  validates :minimum_target, numericality: {
    greater_than_or_equal_to: 0, less_than_or_equal_to: 1000
  }, allow_nil: true

  validates :maximum_target, numericality: {
    greater_than_or_equal_to: 0, less_than_or_equal_to: 1000
  }, allow_nil: true

  validate :maximum_not_below_minimum

  # == benchmark_deviation
  #
  # Returns how far the portfolio's benchmark_target is from the article's own,
  # or nil if either side is blank.
  def benchmark_deviation
    return nil unless benchmark_target.present? && normative_article.benchmark_target.present?
    benchmark_target - normative_article.benchmark_target
  end

  private

  def maximum_not_below_minimum
    return unless minimum_target.present? && maximum_target.present?
    if maximum_target < minimum_target
      errors.add(:maximum_target, "cannot be lower than minimum_target")
    end
  end
end
