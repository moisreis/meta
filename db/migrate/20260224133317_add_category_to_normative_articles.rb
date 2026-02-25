class AddCategoryToNormativeArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :normative_articles, :category, :string
  end
end
