# === normative_article
#
# @author Moisés Reis
# @added 12/4/2025
# @package *Meta*
# @description This model stores a formal rule or guideline that an investment fund follows.
#              It connects articles to investment funds and keeps the text that describes the rule.
#              Other parts of the system read this model to understand how a fund behaves.
# @category *Model*
#
# Usage:: - *[What]* This code block represents a rule or guideline that belongs to investment funds.
#         - *[How]* It stores the article’s text, number, and description, and links it with funds
#           through **InvestmentFundsArticle** so the system can access related information.
#         - *[Why]* It exists so the app can keep structured regulatory information and show it
#           to users in an organized and consistent way.
#
class NormativeArticle < ApplicationRecord

  # Explanation:: This line creates a one-to-many relationship with **InvestmentFundsArticle**.
  #               It tells Rails that each NormativeArticle owns several related join records.
  #               When a NormativeArticle is removed, its related records are removed too.
  has_many :investment_fund_articles,
           class_name: 'InvestmentFundArticle',
           dependent: :destroy

  # Explanation:: This line creates an indirect association with **InvestmentFund** through
  #               the join table **investment_funds_articles**.
  #               It allows access to all investment funds linked to this article.
  has_many :investment_funds, through: :investment_fund_articles

  # Explanation:: This line sets a maximum allowed length for the article_name attribute.
  #               It prevents values longer than 200 characters from being saved.
  #               Blank values are permitted.
  validates :article_name, length: {
    maximum: 200
  }, allow_blank: true

  # Explanation:: This line enforces a maximum length of 50 characters for article_number.
  #               Rails checks this constraint before saving a record.
  #               Blank values are allowed.
  validates :article_number, length: {
    maximum: 50
  }, allow_blank: true

  # Explanation:: This line limits article_body to 5000 characters.
  #               It ensures the stored text remains within a manageable size.
  #               Blank values are permitted.
  validates :article_body, length: {
    maximum: 5000
  }, allow_blank: true

  # Explanation:: This line restricts description to at most 1000 characters.
  #               Rails validates this constraint on save.
  #               The field may be left blank.
  validates :description, length: {
    maximum: 1000
  }, allow_blank: true

  # Explanation:: This line validates that benchmark_target is a number between 0 and 1000.
  #               It ensures that the value stays inside a defined valid range.
  #               Nil values are accepted.
  validates :benchmark_target, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 1000
  }, allow_nil: true

  # Explanation:: This scope returns only records where benchmark_target has a value.
  #               It filters out articles without a defined benchmark.
  scope :with_benchmark, -> { where.not(benchmark_target: nil) }

  # Explanation:: This scope returns articles whose benchmark_target falls within a range.
  #               It receives minimum and maximum values and applies a SQL range filter.
  scope :by_target_range, ->(min, max) { where(benchmark_target: min..max) }

  # app/models/normative_article.rb
  CATEGORIES = %w[Renda\ Fixa\ Geral Renda\ Variável Investimento\ Exterior 100%\ Títulos\ Públicos].freeze

  validates :category, inclusion: { in: CATEGORIES }, allow_blank: true

  # == display_name
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This method returns a readable display name for the article.
  #        It checks what information is available and forms a clear label.
  #        It guarantees that the user always sees a meaningful identifier.
  #
  def display_name

    # Explanation:: This line checks if both article_number and article_name exist.
    #               If they do, it returns a combined string joining them with a colon.
    if article_number.present? && article_name.present?
      "#{article_number}: #{article_name}"
    elsif article_name.present?
      article_name
    elsif article_number.present?
      "Artigo #{article_number}"
    else
      "Artigo Normativo ##{id[0..7]}"
    end
  end

  # == has_benchmark
  #
  # @author Moisés Reis
  # @category *Validation*
  #
  # Validation:: This method checks whether an article has a benchmark value.
  #              It provides a simple boolean result used by other parts of the app.
  #
  def has_benchmark?
    benchmark_target.present?
  end

  # == self.ransackable_attributes
  #
  # @author Moisés Reis
  # @category *Query*
  #
  # Query:: This method lists the associated models (relationships) of the **NormativeArticle**
  #         that advanced query tools like Ransack can join for searching.
  #         It limits available joins to portfolio-related connections.
  #
  def self.ransackable_attributes(auth_object = nil)
    [
      "article_body",
      "article_name",
      "article_number",
      "benchmark_target",
      "created_at",
      "description",
      "id",
      "id_value",
      "updated_at"
    ]
  end
end
