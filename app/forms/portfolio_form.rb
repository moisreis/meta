# Handles validation, normalization, and transformation of portfolio input data
# before persistence.
#
# This form object encapsulates:
# - attribute coercion
# - validation rules
# - nested normative allocation handling
# - persistence-safe attribute generation
#
# Persistence is explicitly excluded and delegated to service objects.
#
# @author Moisés Reis

class PortfolioForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  # ============================================================================
  # MODEL NAME
  # ============================================================================

  # Forces Rails form builders to treat this object as "Portfolio".
  #
  # @return [ActiveModel::Name]
  def self.model_name
    ActiveModel::Name.new(self, nil, "Portfolio")
  end

  # ============================================================================
  # ATTRIBUTES
  # ============================================================================

  attribute :name, :string
  attribute :user_id, :integer
  attribute :annual_interest_rate, :decimal, default: 0.0
  attribute :shared_user_id, :integer
  attribute :grant_crud_permission, :string, default: "read"

  # ============================================================================
  # NESTED FORM COLLECTIONS
  # ============================================================================

  attr_accessor :portfolio_normative_articles_attributes

  # Reader required by form builders for nested attributes.
  #
  # @return [Array<NormativeArticleEntry>]
  def portfolio_normative_articles
    items = if portfolio_normative_articles_attributes.is_a?(Hash)
              portfolio_normative_articles_attributes.values
            else
              Array(portfolio_normative_articles_attributes)
            end

    items.map do |item|
      item.is_a?(NormativeArticleEntry) ? item : NormativeArticleEntry.new(item.to_h)
    end
  end

  # ============================================================================
  # NESTED ENTRY OBJECT
  # ============================================================================

  # Represents a single normative allocation row in the form.
  class NormativeArticleEntry
    include ActiveModel::Model

    attr_accessor :id,
                  :normative_article_id,
                  :benchmark_target,
                  :minimum_target,
                  :maximum_target,
                  :_destroy

    # @return [Boolean]
    def persisted?
      id.present?
    end

    # @return [Array(Integer), nil]
    def to_key
      persisted? ? [id] : nil
    end

    # @return [NormativeArticleEntry]
    def to_model
      self
    end

    # @return [Boolean]
    def marked_for_destruction?
      _destroy.present? && _destroy != "0" && _destroy != false
    end
  end

  # ============================================================================
  # VALIDATIONS
  # ============================================================================

  validates :name,
            presence: true,
            length: {
              minimum: 2,
              maximum: 120
            }

  validates :annual_interest_rate,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 100
            }

  validates :grant_crud_permission,
            inclusion: {
              in: %w[read manage]
            }

  validate :validate_normative_allocations

  # ============================================================================
  # INITIALIZATION
  # ============================================================================

  # @param attributes [Hash]
  def initialize(attributes = {})
    super
    self.portfolio_normative_articles_attributes ||= []
  end

  # ============================================================================
  # SERIALIZATION
  # ============================================================================

  # Returns persistence-safe attributes for the Portfolio model.
  #
  # @return [Hash]
  def to_model_attributes
    {
      name: name,
      user_id: user_id,
      annual_interest_rate: annual_interest_rate,
      portfolio_normative_articles_attributes: normalized_normative_attributes
    }
  end

  # ============================================================================
  # FACTORIES
  # ============================================================================

  # Builds a form object from an existing Portfolio record.
  #
  # @param portfolio [Portfolio]
  # @return [PortfolioForm]
  def self.from_portfolio(portfolio)
    new(
      name: portfolio.name,
      user_id: portfolio.user_id,
      annual_interest_rate: portfolio.annual_interest_rate,
      portfolio_normative_articles_attributes:
        portfolio.portfolio_normative_articles.map do |article|
          {
            id: article.id,
            normative_article_id: article.normative_article_id,
            benchmark_target: article.benchmark_target,
            minimum_target: article.minimum_target,
            maximum_target: article.maximum_target
          }
        end
    )
  end

  private

  # ============================================================================
  # NORMATIVE NORMALIZATION
  # ============================================================================

  # Removes fully blank nested rows.
  #
  # @return [Array<Hash>]
  def normalized_normative_attributes
    rows = if portfolio_normative_articles_attributes.is_a?(Hash)
             portfolio_normative_articles_attributes.values
           else
             Array(portfolio_normative_articles_attributes)
           end

    rows
      .map(&:to_h)
      .reject do |row|
        row.except(:id, :_destroy, "id", "_destroy").values.all?(&:blank?)
      end
  end

  # ============================================================================
  # BUSINESS VALIDATIONS
  # ============================================================================

  # Ensures normative allocation consistency rules.
  #
  # @return [void]
  def validate_normative_allocations
    normalized_normative_attributes.each_with_index do |row, index|
      minimum = decimal_value(row[:minimum_target] || row["minimum_target"])
      benchmark = decimal_value(row[:benchmark_target] || row["benchmark_target"])
      maximum = decimal_value(row[:maximum_target] || row["maximum_target"])

      if minimum && maximum && minimum > maximum
        errors.add(:base, "Linha #{index + 1}: mínimo não pode ser maior que o máximo")
      end

      next unless benchmark

      if minimum && benchmark < minimum
        errors.add(:base, "Linha #{index + 1}: benchmark abaixo do mínimo")
      end

      if maximum && benchmark > maximum
        errors.add(:base, "Linha #{index + 1}: benchmark acima do máximo")
      end
    end
  end

  # ============================================================================
  # TYPE COERCION
  # ============================================================================

  # Converts input value into BigDecimal.
  #
  # @param value [Object]
  # @return [BigDecimal, nil]
  def decimal_value(value)
    return nil if value.blank?

    BigDecimal(value.to_s)
  rescue ArgumentError
    nil
  end
end
