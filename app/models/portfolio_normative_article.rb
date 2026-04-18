# == Schema Information
#
# Table name: portfolio_normative_articles
#
# [Run 'bundle exec annotate --models' to update this block]
#
# @author Moisés Reis

# Join model linking a Portfolio to a NormativeArticle for compliance reporting. [cite: 35]
#
# This class stores portfolio-specific benchmarks, minimum, and maximum targets.
# These values are used to override or compare against the article's default
# targets during the generation of compliance reports. [cite: 36]
#
# @author Moisés Reis [cite: 37]
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

  # Calculates the difference between the portfolio benchmark and the article benchmark. [cite: 60]
  #
  # @return [BigDecimal, nil] The deviation value or nil if targets are missing.
  def benchmark_deviation
    return nil unless benchmark_target.present? && normative_article.benchmark_target.present?
    benchmark_target - normative_article.benchmark_target
  end

  private

  # Validates that the maximum target is not numerically lower than the minimum target. [cite: 81]
  #
  # @return [void] [cite: 69]
  def maximum_not_below_minimum
    return unless minimum_target.present? && maximum_target.present?
    if maximum_target < minimum_target
      errors.add(:maximum_target, "cannot be lower than minimum_target")
    end
  end
end
