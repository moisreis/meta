# frozen_string_literal: true

# Provides presentation logic for normative article display formatting.
#
# This presenter encapsulates formatting rules for rendering human-readable
# representations of normative articles based on available attributes such as
# article number, name, and identifier.
#
# @author Moisés Reis

class NormativeArticlesPresenter

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # Initializes the presenter with a normative article model instance.
  #
  # @param article [Object] Normative article domain model.
  def initialize(article)
    @article = article
  end

  # ==========================================================================
  # PUBLIC METHODS
  # ==========================================================================

  # Returns a formatted display name for the normative article.
  #
  # The formatting priority is:
  # 1. "number - name" if both attributes exist
  # 2. name only if present
  # 3. "Artigo X" if only number exists
  # 4. fallback to truncated identifier
  #
  # @return [String] Human-readable article label.
  def display_name
    number = @article.article_number
    name   = @article.article_name
    id     = @article.id.to_s

    if number.present? && name.present?
      "#{number} - #{name}"
    elsif name.present?
      name
    elsif number.present?
      "Artigo #{number}"
    else
      "Artigo Normativo ##{id.first(8)}"
    end
  end

  # Returns string representation of the presenter.
  #
  # @return [String] Display name for the article.
  def to_s
    display_name
  end
end
