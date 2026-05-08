class NormativeArticlesPresenter
  def initialize(article)
    @article = article
  end

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

  def to_s
    display_name
  end
end