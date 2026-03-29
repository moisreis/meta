class AddFieldsToPortfolioNormativeArticles < ActiveRecord::Migration[8.1]
  def change
    add_reference :portfolio_normative_articles, :portfolio,
                  null: false,
                  foreign_key: { to_table: "public.portfolios" }

    add_reference :portfolio_normative_articles, :normative_article,
                  null: false,
                  foreign_key: { to_table: "public.normative_articles" }

    add_column :portfolio_normative_articles, :benchmark_target, :decimal, precision: 8, scale: 4
    add_column :portfolio_normative_articles, :minimum_target,   :decimal, precision: 8, scale: 4
    add_column :portfolio_normative_articles, :maximum_target,   :decimal, precision: 8, scale: 4

    add_index "public.portfolio_normative_articles",
              [:portfolio_id, :normative_article_id],
              unique: true,
              name: "index_portfolio_normative_articles_uniqueness"
  end
end
